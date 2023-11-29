# config

rez configuration files. See https://rez.readthedocs.io/en/latest/configuring_rez.html.

# prerequisites

[//]: # (TODO update when suite created for pipeline deployment)

For `deploy.py` :

- git is available on the system
- environment variable `KNOTS_SKYNET_PATH` is set
- user have access to the Knots filesystem
- `pythonning` package is resolved

# workflow

## editing an existing config

- edit your config  
- commit your change
- merge to main if you were in a branch
- deploy as per the usual guidelines (TODO: add doc link)


## creating a new config file

- Create your new config
- Add it to the CONFIGS list in `deploy.py`
- deploy as usual