#!/bin/bash

# Use virtualenv 'venv' if exists
for v in \
    "./venv/bin/activate" \
    "./venv/local/bin/activate" # python 3.10
do
    [[ -f $v ]] && . $v
done

install_req(){
    pip3 install -U $(python3 pygubudesigner_.py req) \
    'black>=22.3.0' 'isort>=5.9.2'  'setuptools>=57.3.0' \
    'wheel>=0.37.0' 'twine>=4.0.0'  'pip>=22.1.1'
}

blk(){
    black -l 80 --exclude="venv/" [[ $# -eq 0 ]] && echo '.' || echo $@
}

sort_imports(){
    isort -v ./setup.py
    isort -v ./pygubudesigner/
    blk ./setup.py
    blk ./pygubudesigner/

    if [[ -d ../pygubu ]] # 
    then
        isort -v ../pygubu/setup.py
        isort -v ../pygubu/pygubudesigner/
        blk ../pygubu/setup.py
        blk ../pygubu/pygubu/
    fi
}

sort_imports_commit(){
    sort_imports
    git add . && git commit -m 'sort imports and autopep8'
}

_xgettext(){
    xgettext -L glade \
        --output=pygubudesigner/locale/pygubu.pot \
        $(find ./pygubudesigner/ui -name "*.ui")

    xgettext --join-existing \
        --language=Python \
        --keyword=_ \
        --output=pygubudesigner/locale/pygubu.pot \
        --from-code=UTF-8 \
        `find ./pygubudesigner -name "*.py"`

    for _po in $(find ./pygubudesigner/locale -name "*.po")
    do
        msgmerge $_po ./pygubudesigner/locale/pygubu.pot -U
    done

}

_msgfmt(){
    for _po in $(find ./pygubudesigner/locale -name "*.po")
    do
        msgfmt -o ${_po/.po/.mo}  $_po
    done
}

_build(){
    _msgfmt # compile .po files
    cd ../pygubu
    rm -rf ./dist/* ./build/*
    python3 setup.py sdist bdist_wheel
    
    cd ../pygubu-designer
    rm -rf ./dist/* ./build/*
    cp -r ../pygubu/dist/ .
    python3 setup.py sdist bdist_wheel
}

_serve(){
    # default port is 8080
    _port=`[[ -z $1 ]] && echo "8080" || echo $1`
    python3 -m http.server $_port
}

build_and_serve(){
    _build
    cd dist
    _serve $1
    cd ..
}

build_and_upload(){
    _build
    twine upload dist/*
}

_install(){
    pip3 install ./dist/*.whl
}

build_and_install(){
    _build
    _install
}

_test(){
    # uninstall all
    pip3 uninstall pygubu pygubu-designer appdirs Mako -y
    build_and_install
    pygubu-designer
}

ir(){   install_req;            }
p8(){   auto_sort_pep8;         }
p8c(){  auto_sort_pep8_commit;  }
po(){   _xgettext;              }
msgf(){ _msgfmt;                }
_b(){   _build;                 }
_s(){   _serve;                 }
bs(){   build_and_serve $1;     }
bup(){  build_and_upload;       }
bi(){   build_and_install;      }
ts(){   _test;                  }

if [ $# -eq 0 ]
  then
    echo "Bash utility to facilitate development."
    echo "usage: pygubudesigner.sh [option] [args]"
    echo "Available options:"
    echo "  ts : test"
    echo "  bi : build and install."
    echo "  bs : build and serve."
    echo "  bup: build and upload."
    echo "  po : update po file."
else
    $@
fi