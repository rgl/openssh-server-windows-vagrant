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
    default='10.10.10.100',
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
