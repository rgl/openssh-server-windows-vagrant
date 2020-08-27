import argparse
import os.path
import sys
import warnings
from paramiko.client import SSHClient, WarningPolicy

# for not upsetting PowerShell... redirect warnings from stderr to stdout.
def _showwarningstdout(message, category, filename, lineno, file=None, line=None):
    sys.stdout.write(warnings.formatwarning(message, category, filename, lineno))
warnings.showwarning = _showwarningstdout

parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='execute a remote command over ssh')
parser.add_argument(
    '--hostname',
    default='sshd.example.com',
    type=str,
    help='the sshd hostname')
parser.add_argument(
    '--port',
    default=22,
    type=int,
    help='the sshd port')
parser.add_argument(
    '--username',
    default='vagrant',
    type=str,
    help='the username')
parser.add_argument(
    '--password',
    default=None,
    type=str,
    help='the password to use (you must use --password or --key-file)')
parser.add_argument(
    '--key-file',
    default=None,
    type=str,
    help='the key to use (you must use --password or --key-file)')
parser.add_argument(
    '--known-hosts-file',
    default='~/.ssh/known_hosts',
    type=str,
    help='known_hosts file location)')
parser.add_argument(
    '--command',
    default='whoami /all',
    type=str,
    help='an integer for the accumulator')
args = parser.parse_args()

client = SSHClient()

# trust the host only when inside the known_hosts file or trust any host.
if args.known_hosts_file:
    client.load_host_keys(os.path.expanduser(args.known_hosts_file))
else:
    client.set_missing_host_key_policy(WarningPolicy())

# NB paramiko ONLY supports the legacy PEM private key format of:
#       -----BEGIN RSA PRIVATE KEY-----
# NB it does NOT support the more recent format of:
#       -----BEGIN OPENSSH PRIVATE KEY-----
#    if you try, it will error with a strange error of:
#       paramiko.ssh_exception.SSHException: Invalid key
#       ValueError: ('Invalid private key', [
#           _OpenSSLErrorWithText(
#               code=67764350,
#               lib=4,
#               func=160,
#               reason=126,
#               reason_text=b'error:040A007E:rsa routines:RSA_check_key_ex:iqmp not inverse of q')])
# NB in theory support for the new recent format was added in paramiko 2.7,
#    but its not working for me when running in Windows.
#    see https://github.com/paramiko/paramiko/pull/1343
#    see https://github.com/paramiko/paramiko/issues/1517
print('connecting to %s:%d...' % (args.hostname, args.port))
client.connect(
    args.hostname,
    args.port,
    args.username,
    args.password,
    key_filename=args.key_file,
    allow_agent=False,
    look_for_keys=False)

print('executing the %s command...' % args.command)
stdin, stdout, stderr = client.exec_command(args.command)
stdin.close()
for line in stdout.readlines():
    print(line.rstrip())
for line in stderr.readlines():
    print(line.rstrip())

client.close()
