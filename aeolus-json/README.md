`aeolus-jsos` aims to provide tools to manipulate json files of the
Aeolus project.

Currently, we can
- Validate universe-automaton.json file 
- Generate zephyrus universe file from universe-automaton


Dependancies
------------

`$ pip install jsonschema`

(or `python setup.py install`)


Use it
------

`./aeolus-json.py -h`


Examples
--------

- `./aeolus-json.py zephyrus examples/1lb-3wp-1db.universe-automatons.json`
- `./aeolus-json.py validation stateful examples/1lb-3wp-1db.universe-automatons.json`