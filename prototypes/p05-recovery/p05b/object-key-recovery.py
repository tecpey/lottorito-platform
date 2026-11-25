#!/usr/bin/env python3
"""Synthetic-only P-05B object-byte and envelope-key recovery drill."""
from __future__ import annotations
import base64, hashlib, json, os, shutil, subprocess
from pathlib import Path
from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

ROOT=Path("/tmp/lottorito-p05b")
ACTIVE=ROOT/"active-object-store"; KEYS=ROOT/"active-key-recovery"
OBJ_BAK=ROOT/"backup-object-store"; KEY_BAK=ROOT/"backup-key-recovery"
REST_OBJ=ROOT/"restored-object-store"; REST_KEY=ROOT/"restored-key-recovery"
TENANT="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
OBJECT="40000000-0000-4000-8000-0000000000b5"
KEY_ID="p05b-synthetic-kek-v1"
DB_PASSWORD="p05-admin-only-not-production"

class RecoveryError(Exception): pass
def fail(message): raise RecoveryError(message)
def psql(sql):
    env=os.environ.copy(); env["PGPASSWORD"]=DB_PASSWORD
    r=subprocess.run(["psql","-X","-h","127.0.0.1","-p","55432","-U","postgres","-d","lottorito_p05","-At","-v","ON_ERROR_STOP=1","-c",sql],check=True,text=True,capture_output=True,env=env)
    return r.stdout.strip()
def write_json(path,value):
    path.write_text(json.dumps(value,sort_keys=True,separators=(",",":"))+"\n"); path.chmod(0o600)
def verify_ciphertext(folder):
    m=json.loads((folder/"manifest.json").read_text()); blob=(folder/"payload.aesgcm").read_bytes()
    if m.get("tenant_id")!=TENANT or m.get("object_id")!=OBJECT or m.get("key_id")!=KEY_ID or m.get("format")!="AES-256-GCM" or m.get("manifest_version")!=1:
        fail("manifest context mismatch")
    if not isinstance(m.get("plaintext_size"),int) or m["plaintext_size"]<0 or not isinstance(m.get("ciphertext_size"),int):
        fail("manifest size fields invalid")
    if len(m.get("plaintext_sha256",""))!=64 or any(ch not in "0123456789abcdef" for ch in m["plaintext_sha256"]):
        fail("manifest plaintext digest invalid")
    nonce=base64.b64decode(m["payload_nonce"],validate=True)
    if len(nonce)!=12: fail("payload nonce length invalid")
    if hashlib.sha256(blob).hexdigest()!=m["ciphertext_sha256"]: fail("ciphertext checksum mismatch")
    if len(blob)!=m["ciphertext_size"]: fail("ciphertext size mismatch")
    return m
def recover(folder,key_folder,out):
    m=verify_ciphertext(folder); root=key_folder/"synthetic-recovery-root.bin"
    if not root.is_file(): fail("recovery root key unavailable")
    kek=root.read_bytes()
    if len(kek)!=32: fail("recovery root key has invalid length")
    env=json.loads((folder/"key-envelope.json").read_text())
    if env.get("tenant_id")!=TENANT or env.get("key_id")!=KEY_ID or env.get("object_id")!=OBJECT: fail("key envelope context mismatch")
    wrap_nonce=base64.b64decode(env["wrap_nonce"],validate=True)
    wrapped_dek=base64.b64decode(env["wrapped_dek"],validate=True)
    if len(wrap_nonce)!=12 or len(wrapped_dek)<48: fail("key envelope encoding invalid")
    dek=AESGCM(kek).decrypt(wrap_nonce,wrapped_dek,f"{TENANT}|{KEY_ID}|{OBJECT}".encode())
    plain=AESGCM(dek).decrypt(base64.b64decode(m["payload_nonce"],validate=True),(folder/"payload.aesgcm").read_bytes(),f"{TENANT}|{OBJECT}|v1".encode())
    digest=hashlib.sha256(plain).hexdigest()
    if len(plain)!=m["plaintext_size"]: fail("plaintext size mismatch")
    if digest!=m["plaintext_sha256"]: fail("plaintext checksum mismatch")
    out.write_bytes(plain)
    return plain,m
def main():
    shutil.rmtree(ROOT,ignore_errors=True)
    for p in (ACTIVE,KEYS,OBJ_BAK,KEY_BAK,REST_OBJ,REST_KEY): p.mkdir(parents=True)
    kek=AESGCM.generate_key(bit_length=256); (KEYS/"synthetic-recovery-root.bin").write_bytes(kek); (KEYS/"synthetic-recovery-root.bin").chmod(0o600)
    plain=b"LOTTORITO-P05B-SYNTHETIC-OBJECT\x00"+bytes(range(256))*17+b"\nobject-recovery-fixture\n"
    dek=AESGCM.generate_key(bit_length=256); nonce=os.urandom(12); wrap_nonce=os.urandom(12)
    cipher=AESGCM(dek).encrypt(nonce,plain,f"{TENANT}|{OBJECT}|v1".encode())
    wrapped=AESGCM(kek).encrypt(wrap_nonce,dek,f"{TENANT}|{KEY_ID}|{OBJECT}".encode())
    (ACTIVE/"payload.aesgcm").write_bytes(cipher)
    write_json(ACTIVE/"key-envelope.json",{"tenant_id":TENANT,"key_id":KEY_ID,"object_id":OBJECT,"wrap_nonce":base64.b64encode(wrap_nonce).decode(),"wrapped_dek":base64.b64encode(wrapped).decode()})
    digest=hashlib.sha256(plain).hexdigest()
    write_json(ACTIVE/"manifest.json",{"tenant_id":TENANT,"object_id":OBJECT,"format":"AES-256-GCM","plaintext_size":len(plain),"plaintext_sha256":digest,"ciphertext_size":len(cipher),"ciphertext_sha256":hashlib.sha256(cipher).hexdigest(),"payload_nonce":base64.b64encode(nonce).decode(),"key_id":KEY_ID,"manifest_version":1})
    if (ACTIVE/"payload.aesgcm").read_bytes()==plain: fail("plaintext unexpectedly present in object backup")
    psql(f"INSERT INTO public.object_refs(tenant_id,object_id,content_sha256) VALUES ('{TENANT}','{OBJECT}','{digest}')")
    # Two independent recovery sets: object payload and synthetic key-recovery material.
    shutil.copytree(ACTIVE,OBJ_BAK,dirs_exist_ok=True); shutil.copytree(KEYS,KEY_BAK,dirs_exist_ok=True)
    shutil.rmtree(ACTIVE); shutil.rmtree(KEYS)
    try: recover(OBJ_BAK,ROOT/"missing-key",ROOT/"missing.out"); fail("recovery succeeded without key")
    except RecoveryError as e:
        if "unavailable" not in str(e): raise
    badmeta=ROOT/"wrong-manifest-context"; shutil.copytree(OBJ_BAK,badmeta)
    mm=json.loads((badmeta/"manifest.json").read_text()); mm["tenant_id"]="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"; write_json(badmeta/"manifest.json",mm)
    try: recover(badmeta,KEY_BAK,ROOT/"bad-manifest.out"); fail("wrong-tenant manifest accepted")
    except RecoveryError as e:
        if "manifest context mismatch" not in str(e): raise
    bad=ROOT/"corrupt-object"; shutil.copytree(OBJ_BAK,bad)
    b=bytearray((bad/"payload.aesgcm").read_bytes()); b[len(b)//2]^=1; (bad/"payload.aesgcm").write_bytes(b)
    try: recover(bad,KEY_BAK,ROOT/"bad-object.out"); fail("corrupt object accepted")
    except RecoveryError as e:
        if "checksum mismatch" not in str(e): raise
    badkey=ROOT/"corrupt-envelope"; shutil.copytree(OBJ_BAK,badkey)
    env=json.loads((badkey/"key-envelope.json").read_text()); w=bytearray(base64.b64decode(env["wrapped_dek"])); w[-1]^=1
    env["wrapped_dek"]=base64.b64encode(w).decode(); write_json(badkey/"key-envelope.json",env)
    try: recover(badkey,KEY_BAK,ROOT/"bad-key.out"); fail("corrupt wrapped DEK accepted")
    except InvalidTag: pass
    shutil.copytree(OBJ_BAK,REST_OBJ,dirs_exist_ok=True); shutil.copytree(KEY_BAK,REST_KEY,dirs_exist_ok=True)
    restored,m=recover(REST_OBJ,REST_KEY,ROOT/"recovered-plaintext.bin")
    dbhash=psql(f"SELECT content_sha256 FROM public.object_refs WHERE tenant_id='{TENANT}' AND object_id='{OBJECT}'")
    if hashlib.sha256(restored).hexdigest()!=dbhash or len(restored)!=m["plaintext_size"]: fail("restored bytes differ from DB reference")
    env=os.environ.copy(); env["PGPASSWORD"]="p05-tenant-b-not-production"
    r=subprocess.run(["psql","-X","-h","127.0.0.1","-p","55432","-U","p05_tenant_b","-d","lottorito_p05","-At","-c",f"SELECT count(*) FROM public.object_refs WHERE object_id='{OBJECT}'"],check=True,text=True,capture_output=True,env=env)
    if r.stdout.strip()!="0": fail("cross-tenant object metadata visible")
    print(f"object_id={OBJECT}\nplaintext_bytes={len(restored)}\nplaintext_sha256={dbhash}")
    print("object_backup_restore=PASS\nmissing_key_fail_closed=PASS\nmanifest_context_mismatch_rejected=PASS\ncorrupt_object_rejected=PASS\ncorrupt_wrapped_dek_rejected=PASS\ntenant_object_reference_isolation=PASS\nP05B_OBJECT_KEY_RESULT=PASS")
if __name__=="__main__": main()
