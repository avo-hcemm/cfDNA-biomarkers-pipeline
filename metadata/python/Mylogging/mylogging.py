'''
Created on Jul 17, 2024

@author: avo
'''
import logging
import os

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def setup_logger(name: str, log_file: str, level=logging.INFO):
    """
    Sets up and returns a logger with a file handler and a console handler.
    Avoids duplicate handlers if called multiple times with the same name.
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)

    # Make this logger independent from root, and ensure a clean set of handlers.
    logger.propagate = False
    if logger.handlers:
        logger.handlers.clear()

    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    fmt = logging.Formatter('%(asctime)s [%(levelname)s] %(name)s - %(message)s')

    # File handler: write INFO+ to file
    fh = logging.FileHandler(log_file)
    fh.setLevel(level)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    # Console handler: only show ERROR+
    ch = logging.StreamHandler()  # defaults to sys.stderr
    ch.setLevel(logging.ERROR)
    ch.setFormatter(fmt)
    logger.addHandler(ch)

    return logger