# Python library template for Aspect CLI

First run `aspect init` and choose Python.

Then run this (replacing `mylib` with the folder you'd like to create):

```
./tools/copier copy gh:alexeagle/aspect-template-python-lib mylib
./tools/buildozer "add data //${_}:requirements" //requirements:requirements.all
```

Finally update the `requirements/all.in` file with a new `-r` line pointing to the new requirements.txt file.
