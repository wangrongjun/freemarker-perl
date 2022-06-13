scp freemarker* centos:~
ssh centos "sed -i 's|\r||g' ~/freemarker*"
ssh centos "chmod u+x ~/freemarker.pl"
ssh centos "cd ~ && bash freemarker-test.sh"
