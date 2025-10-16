#!/bin/bash

echo "Building vim from source..."
if [ ! -d "$HOME/vim" ]; then
    git clone --depth=1 https://github.com/vim/vim.git $HOME/vim
fi

cd $HOME/vim/src
./configure --with-features=huge \
            --with-x=yes

make -j$(nproc)
sudo make install

echo "Vim built and installed. Checking clipboard support:"
vim --version | grep clipboard
