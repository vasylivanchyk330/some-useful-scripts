import os
import subprocess
import datetime
import argparse

def backup_docker_volumes(volumes, backup_dir):
    for volume in volumes:
        try:
            timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
            backup_file = os.path.join(backup_dir, f"{volume}_{timestamp}.tar.gz")
            subprocess.run(["docker", "run", "--rm", "-v", f"{volume}:/volume", "-v", f"{backup_dir}:/backup", "ubuntu", "tar", "czvf", f"/backup/{backup_file}", "-C", "/volume", "."], check=True)
            print(f"Volume {volume} backed up to {backup_file}")
        except subprocess.CalledProcessError as e:
            print(f"Error occurred while backing up {volume}: {e}")

def main():
    parser = argparse.ArgumentParser(description="Backup Docker volumes")
    parser.add_argument("volumes", nargs='+', help="List of Docker volumes to backup")
    parser.add_argument("-d", "--backup-dir", required=True, help="Backup directory")

    args = parser.parse_args()

    backup_docker_volumes(args.volumes, args.backup_dir)

if __name__ == "__main__":
    main()
