# install dependencies.
# NB you need gcc installed in msys2 to be able to install
#    ed25519 and bcrypt_pbkdf.
#    see provision-windows.ps1.
gem install ed25519 bcrypt_pbkdf net-ssh

# NB the bcrypt_pbkdf does not compile for some reason... so have
#    to comment it out.
# TODO figure out why it does not compile.
$libPath = Resolve-Path C:\tools\ruby27\lib\ruby\gems\*\gems\bcrypt_pbkdf-*-x64-mingw32\lib\bcrypt_pbkdf.rb
Set-Content `
    -Encoding Ascii `
    $libPath `
    (
        (Get-Content -Raw $libPath) `
            -replace '(require "bcrypt_pbkdf_ext")','#$1' `
    )

# run.
ruby main.rb
