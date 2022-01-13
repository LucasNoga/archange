# Archange project

Create an history files of your server

#### Version v1.1.0

## Get Started

You need to create a file call setting.conf in the repo like this

```bash
$ git clone https://github.com/LucasNoga/archange.git
$ cd archange
```

Then create your configuration file **settings.conf**

```bash
$ touch settings.conf
$ vim settings.conf
```

Put this into the file with your server intels

```bash
IP="XX.XX.XX.XX"
PORT="XX"
ARCHANGE_USER="XXXXXX"
PASSWORD="XXXXXX"
ARCHANGE_PATH="XXXXXX"
```

- IP (mandatory) : Ip of your server
- PORT (mandatory): SSH port of your server
- ARCHANGE_USER (mandatory): User which has access to the server
- PASSWORD (optional): Password of the user to get access to the server (if you not specified in your config it will be requested later)
- ARCHANGE_PATH (optional): Path on your server to get the history files (if you not specified in your config it will be requested later )
  you can complete the **XX** with your server credentials, careful your user needs read and write access

Example

```bash
IP="192.168.1.1"
PORT="21"
ARCHANGE_USER="toto"
PASSWORD="password"
ARCHANGE_PATH="/server/dev" # get history files to the folder /server/dev
```

## How to use

```bash
$ chmod +x archange.sh
$ cp settings.sample.conf settings.conf
$ ./archange.sh
```

Then follow instructions in your terminal

### Export configuration of DSM

- Go to your Synology access then Panel Configuration > Configuration Backup
- Click to `Export`

### Manual Process

- Create a file in your server with `ls -R` command in choosen repository
- Copy in your local machine it choosen folder with `scp` this file

## Trouble-shootings

If you have any difficulties, problems or enquiries please let me an issue [here](https://github.com/LucasNoga/Archange/issues/new)

## Credits

Made by Lucas Noga
Licensed under GPLv3.
