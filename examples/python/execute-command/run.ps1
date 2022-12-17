# install dependencies.
python -m pip install -r requirements.txt
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# run with username and password.
Write-Host 'Executing with password...'
python main.py --password vagrant
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# run with username and key.
Write-Host 'Running with key...'
python main.py --key-file c:/vagrant/tmp/id_rsa
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
