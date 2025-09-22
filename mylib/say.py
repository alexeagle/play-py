import cowsay
from os import path, getenv, sep

# Note, we could use https://pypi.org/project/bazel-runfiles/
# for a more robust lookup mechanism of files provided in the `data` attribute.
WORKSPACE=getenv('BAZEL_WORKSPACE', '')
FOLDER=path.dirname(__file__).split(WORKSPACE + sep)[-1]


def moo(text):
    cowsay.cow(text)

def moo_stamped(text):
    with open(path.join(FOLDER, "header.txt"), "r") as header:
        cowsay.cow(header.read() + text)
