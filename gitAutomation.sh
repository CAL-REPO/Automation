#!/bin/bash

#Source personal enviorment file
ENV="$PWD/env.sh"

if [ ! -f "$ENV"]; then
  echo 'env.sh file is not exist'
  exit 1
else
  . "$ENV"
fi

#Set user home directory
#If use '~' for home directory, shell script will read as '/root' instead of '/home/<user>' when excute with 'sudo'
HOME_DIR="/home/$USER"

#Check OpenSSH is installed
if [ -x "$(command -v ssh)" ]; then
  echo 'OpenSSH is installed.'
else
  echo 'OpenSSH is not installed.'
  sudo apt-get install -y openssh
fi

#Check OpenSSH folder for configuration and key
SSH_DIR="$HOME_DIR/.ssh"
if [ ! -d "$SSH_DIR" ]; then
  mkdir "$SSH_DIR"
fi

#Install Git and GitHub
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install git -y
sudo apt-get install -y gh

#Set personal Git information
git config --global user.email $GIT_USER_EMAIL
git config --global user.name $GIT_USER_NAME
git config --global core.autocrlf input

#Set personal Git SSH public key, private key and those permission
sudo cp "$GIT_KEY_SOURCE/$GIT_SSH_KEY" $SSH_DIR
sudo cp "$GIT_KEY_SOURCE/$GIT_SSH_KEY.pub" $SSH_DIR
sudo cp "$GIT_KEY_SOURCE/$GIT_TOKEN" $SSH_DIR
sudo chmod 600 $SSH_DIR/$GIT_SSH_KEY
sudo chmod 644 $SSH_DIR/$GIT_SSH_KEY.pub
sudo chmod 644 $SSH_DIR/$GIT_TOKEN
sudo chown $USER:$USER $SSH_DIR/$GIT_SSH_KEY
sudo chown $USER:$USER $SSH_DIR/$GIT_SSH_KEY.pub
sudo chown $USER:$USER $SSH_DIR/$GIT_TOKEN

#Set personal Git SSH private key to OpenSSH configuration file
SSH_CONF="$SSH_DIR/config"

if [ ! -f "$SSH_CONF"]; then
  # Create the file and add the three lines
  sudo touch $SSH_CONF
  sudo chmod 600 $SSH_CONF
  sudo echo "Host github.com" >> $SSH_CONF
  sudo echo "  HostName github.com" >> $SSH_CONF
  sudo echo "  User git" >> $SSH_CONF
  sudo echo "  IdentityFile $SSH_DIR/$GIT_SSH_KEY" >> $SSH_CONF
else
  if grep -q "Host github.com" "$SSH_CONF"; then
    # Overwrite the second and third lines
    sudo sed -i '#Host github.com#{n;s#.*#  HostName github.com#;n;s#.*#  User git#;n;s#.*#  IdentityFile '"$SSH_DIR/$GIT_SSH_KEY"'#;}' $SSH_CONF
  else
    # Add the three lines at the end of the file
    sudo echo "Host github.com" >> $SSH_CONF
    sudo echo "  HostName github.com" >> $SSH_CONF
    sudo echo "  User git" >> $SSH_CONF   
    sudo echo "  IdentityFile $SSH_DIR/$GIT_SSH_KEY" >> $SSH_CONF
  fi
fi

#Add personal Git SSH private key to OpenSSH
eval "$(ssh-agent -s)"
ssh-add $SSH_DIR/$GIT_SSH_KEY

#Check can access via SSH with password
ssh -T git@github.com

#Set ZSH configuration file to login GitHUb with token automatically whenever ZSH start
ZSH_CONF="$HOME_DIR/.zshrc"
BASH_CONF="$HOME_DIR/.bashrc"

if [ ! -f "$ZSH_CONF"]; then
  echo "ZSH is not installed"
  if grep -q "gh auth login" "$BASH_CONF"; then
    echo "Already set gh auth login with token in ~/.bashrc"
    exit 1
  else
    echo 'echo $(cat '$SSH_DIR/$GIT_TOKEN')' '| gh auth login --with-token' >> $BASH_CONF
    echo "Please excuete 'source ~/.bashrc'"
  fi  
else
  if grep -q "gh auth login" "$ZSH_CONF"; then
    echo "Already set gh auth login with token in ~/.zshrc"
    exit 1
  else
    echo 'echo $(cat '$SSH_DIR/$GIT_TOKEN')' '| gh auth login --with-token' >> $ZSH_CONF
    echo "Please excuete 'source ~/.zshrc'"
  fi
fi