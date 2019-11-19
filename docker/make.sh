# The only point of this script is to pass the download URL for the AutoPhrase
# archive file to the Dockerfile--we can create an archive here instead, and
# pass that in, but in Windows, scripts in such an archive end up with Windows 
# linefeeds under typical git setings, and won't execute properly in Linux.
if REPO_URL=$(git remote get-url origin) 2> /dev/null; then
    REPO=$(echo $REPO_URL | sed "s/\.git//")
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
else
    REPO=https://github.com/shangjingbo1226/AutoPhrase  
    BRANCH=master
fi

# In a Windows bash shell, "sudo" won't work.  Note that the shell itself
# must be elevated, though.
su 2> /dev/null
docker build --build-arg repo=$REPO --build-arg branch=$BRANCH \
    -t remenberl/autophrase .
