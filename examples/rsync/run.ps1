Write-Output 'Installing the msys2 rsync client...'
Bash 'pacman --noconfirm -Sy rsync'

Write-Output 'Executing the msys2 rsync client...'
Bash @'
sleep_duration=1
attempts=3
declare -i failed_attempts=0

for i in $(seq 1 $attempts); do
    echo "Running rsync attempt $i of $attempts..."
    if rsync \
        --verbose \
        --archive \
        --delete \
        --compress \
        --copy-links \
        --no-owner \
        --no-group \
        --exclude .vagrant/ \
        --exclude .git/ \
        --exclude *.box \
        /c/vagrant/ \
        vagrant@sshd.example.com:/rsync-example; then
        echo "SUCCEEDED: Rsync succeeded on attempt $i"
    else
        echo "FAILED: Rsync failed on attempt $i"
        failed_attempts+=1
    fi
    if [ $i -ne $attempts ]; then
        echo "Waiting ${sleep_duration} seconds before the next attempt..."
        sleep $sleep_duration
    fi
done

if [ $failed_attempts -gt 0 ]; then
    echo "FAILED: Failed attempts $failed_attempts out of $attempts"
    exit 1
fi
'@
