import argparse
import warnings
import sys
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
    help='an integer for the accumulator')
parser.add_argument(
    '--port',
    default=22,
    type=int,
    help='an integer for the accumulator')
parser.add_argument(
    '--username',
    default='vagrant',
    type=str,
    help='an integer for the accumulator')
parser.add_argument(
    '--password',
    default='vagrant',
    type=str,
    help='an integer for the accumulator')
parser.add_argument(
    '--key_filename',
    default='c:/vagrant/tmp/id_rsa',
    type=str,
    help='an integer for the accumulator')
parser.add_argument(
    '--command',
    default='whoami /all',
    type=str,
    help='an integer for the accumulator')
args = parser.parse_args()

client = SSHClient()
# TODO verify the host key.
#client.load_system_host_keys()
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
    key_filename=args.key_filename)

print('executing the %s command...' % args.command)
stdin, stdout, stderr = client.exec_command(args.command)
stdin.close()
for line in stdout.readlines():
    print(line.rstrip())
for line in stderr.readlines():
    print(line.rstrip())

client.close()
