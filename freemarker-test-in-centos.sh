set -euxo pipefail

ssh centos 'rm -rf ~/freemarker-perl && mkdir -p ~/freemarker-perl'
scp -r ../freemarker-perl centos:~
ssh centos "sed -i 's|\r||g' ~/freemarker-perl/freemarker*"
ssh centos "chmod u+x ~/freemarker-perl/freemarker.pl"
ssh centos "cd ~/freemarker-perl && bash freemarker-test.sh"
