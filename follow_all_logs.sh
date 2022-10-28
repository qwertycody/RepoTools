find "/var/log/apache2/" -name "*.log" | xargs tail -f -n 50 | sed 's/\\n/\n/g' &
find "/home/$USER/.pm2/logs" -name "*.log" | xargs tail -f -n 50 | sed 's/\\n/\n/g'