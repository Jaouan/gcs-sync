# GCS-sync

Demo of GCS synchronization using a configuration file.

## Usage
> Ensure that gcloud is authenticated.
> If you are using a `credentials.json`, simply run: `gcloud auth activate-service-account --key-file=./credentials.json`

The **configuration file** consists of 2 columns: The target folder and the source archive.
```
/foo           foo.tar.gz
/bar           https://somewhere/bar.zip
```


### "Soft" synchronization
The destination folder is considered synchronized if it exists. Synchronization does not delete remote files.
```bash
# Soft synchronize.
./sync.sh my_gcs_bucket_id ./bucket.sync

# Dry-run.
DRY_RUN=true ./sync.sh my_gcs_bucket_id ./bucket.sync
```

### Mirror synchronization
All assets is fetched and synchronized. Remote objects that are not part of the synchronization are deleted. Use with caution.
```bash
# Mirror synchronize.
MIRROR=true ./sync.sh my_gcs_bucket_id ./bucket.sync

# Dry-run.
DRY_RUN=true MIRROR=true ./sync.sh my_gcs_bucket_id ./bucket.sync
```
