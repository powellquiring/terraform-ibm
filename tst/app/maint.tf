variable remote {
  description = "Remote IP address that will be accessed via the /remote path"
  default     = "REMOTE"
}

locals {
  // Packages up an app.js nodejs app and the commands to install it as a system service
  shared_app_user_data = <<EOS
#!/bin/sh
apt update -y
apt install nodejs -y
cat > /app.js << 'EOF'
${file("${path.module}/app/app.js")}
EOF
cat > /lib/systemd/system/a-app.service << 'EOF'
${file("${path.module}/app/a-app.service")}
EOF
systemctl daemon-reload
systemctl start a-app
EOS

  user_data = replace(
    local.shared_app_user_data,
    "REMOTE_IP",
    var.remote,
  )
}

output user_data {
  value = local.user_data
}
