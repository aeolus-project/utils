#!/usr/bin/python

import json
from jsonschema import validate
import jsonschema.exceptions
import os

class Port(object):
    def __init__(self, name):
        self.name = name


class State(object):
    def __init__(self, name, initial, successors,
                 provides, requires, conflicts):
        self.name = name
        self.initial = initial
        self.successors = successors
        self.requires = requires
        self.provides = provides
        self.conflicts = conflicts

    @classmethod
    def factory(cls, json):
        name = json['name']
        initial = False
        if 'initial' in json:
            initial = json['initial']

        successors = []
        if 'successors' in json:
            for s in json['successors']:
                successors.append(s)

        provides = []
        if 'provide' in json:
            for (k, v) in json['provide'].items():
                provides.append((Port(k), v))

        requires = []
        if 'require' in json:
            for (k, v) in json['require'].items():
                requires.append((Port(k), v))

        conflicts = []
        if 'conflict' in json:
            for p in json['conflict']:
                conflicts.append(Port(p))

        new = cls(name=name,
                  initial=initial,
                  successors=successors,
                  provides=provides,
                  requires=requires,
                  conflicts=conflicts)

        return new


def json_maybe(json, key, nothing=None):
    try:
        return json[key]
    except KeyError:
        return nothing


class ComponentType(object):
    def __init__(self, name, states, consume, implementations=None):
        self.name = name
        self.states = states
        self.consume = consume
        self.implementations = implementations

    @classmethod
    def factory(cls, json):
        name = json['name']
        states = []
        for s in json['states']:
            states.append(State.factory(s))

        consume = json_maybe(json, 'consume', {})

        new = cls(name=name, states=states, consume=consume)

        return new

    def to_zephyrus(self):
        requires = {}
        provides = {}
        conflicts = []

        for s in self.states:
            for r in s.requires:
                requires.update({r[0].name: r[1]})
            for p in s.provides:
                provides.update({p[0].name: p[1]})
            for c in s.conflicts:
                conflicts.append(c.name)

        ret = {'name': self.name,
               'require': requires,
               'provide': provides,
               'conflict': conflicts,
               'consume': self.consume}

        return ret


class Universe(object):
    def __init__(self, file_universe):
        self.component_types = []

        with open(file_universe, 'r') as f:
            self.json = json.load(f)

        for c in self.json['component_types']:
            self.component_types.append(ComponentType.factory(c))

        # We bind implementation to component types
        for (k, v) in self.json['implementation'].items():
            found = False
            for c in self.component_types:
                if c.name == k:
                    found = True
                    c.implementations = v
            if not found:
                raise ValueError("%s is not a component type!" % k)

        self.repositories = json_maybe(self.json, 'repositories')

    def to_zephyrus(self):
        ret = {}
        component_types = []
        implementations = {}
        for c in self.component_types:
            component_types.append(c.to_zephyrus())
            acc = []
            for i in c.implementations:
                acc.append([i['repository'], i['package']])
            implementations.update({c.name: acc})

        ret.update({'version': 1,
                    'component_types': component_types,
                    'implementation': implementations,
                    'repositories': self.repositories})

        return json.dumps(ret, indent=2)


def validation(args):
    if args.type == "stateful":
        schema_file = os.path.join(
            os.path.dirname(__file__),
            "data/schema_universe_stateful.json")
    elif args.type == "stateless":
        schema_file = os.path.join(
            os.path.dirname(__file__),
            "data/schema_universe_stateless.json")

    print "Validation is using schema '%s'..." % schema_file

    with open(schema_file, 'r') as f:
        schema = json.load(f)

        with open(args.json, 'r') as f:
            try:
                validate(json.load(f), schema)
            except jsonschema.exceptions.ValidationError:
                raise
        print "Validation succeeded."


def zephyrus(args):
    universe = Universe(args.universe)
    print universe.to_zephyrus()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description='Manipulate Aeolus JSON files')
    subparsers = parser.add_subparsers()

    p_validation = subparsers.add_parser(
        'validation',
        help='Validate json file by a schema')
    p_validation.add_argument('type', choices=['stateful', 'stateless'],
                              help="choose the file type that has to be validated")
    p_validation.add_argument(
        'json', type=str, help="validating json file")

    p_validation.set_defaults(func=validation)

    p_zephyrus = subparsers.add_parser(
        'zephyrus',
        help='Generate zephyrus files')
    p_zephyrus.add_argument(
        'universe', type=str, help='universe file with automatons')

    p_zephyrus.set_defaults(func=zephyrus)

    args = parser.parse_args()
    args.func(args)
