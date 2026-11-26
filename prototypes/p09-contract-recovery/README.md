# P-09A Contract Baseline

This directory is a disposable, standard-library-only contract experiment.

Run:

```sh
python3 -m unittest discover -s prototypes/p09-contract-recovery -v
```

The contract deliberately distinguishes product scope (`affiliate_agent`, `lottery`) from platform scope (`lottorito`). The legacy token `shared` is rejected. This validator is not yet wired into P-02 through P-08; that cross-prototype conformance is the remaining P-09B–P-09F work.

No production identities, credentials, provider traffic, database writes or financial operations are used.
