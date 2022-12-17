# install dependencies.
# NB you need gcc installed in msys2 to be able to install
#    ed25519 and bcrypt_pbkdf.
#    see provision-windows.ps1.
gem install ed25519 bcrypt_pbkdf net-ssh
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# run.
ruby main.rb
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
