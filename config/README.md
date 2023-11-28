# config

rez configuration files. See https://rez.readthedocs.io/en/latest/configuring_rez.html.

# workflow

## editing an existing config

- edit your config  
- commit your change
- merge to main if you were in a branch
- run the `deploy.py` script like `python deploy.py`
- inform pipeline team the config has been deployed

## creating a new config file

- Create your new config
- Add it to the CONFIGS list in `deploy.py`
- deploy as usual