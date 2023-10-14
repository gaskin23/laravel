# Define your provider (DigitalOcean)
provider "digitalocean" {
  token = "YOUR_DO_API_TOKEN"
}

# Define a DigitalOcean SSH key (you should create this key beforehand)
resource "digitalocean_ssh_key" "alparslan_ssh_key" {
  name       = "alparslan-ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Define a DigitalOcean droplet (VM)
resource "digitalocean_droplet" "alparslan_vm" {
  name   = "alparslan-vm"
  region = "nyc3"
  size   = "s-2vcpu-2gb"
  image  = "ubuntu-20-04-x64"
  ssh_keys = [digitalocean_ssh_key.alparslan_ssh_key.fingerprint]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
    host        = self.ipv4_address
  }

  # Define the startup script for the VM
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx

              # Install PHP and Composer for Laravel
              apt-get install -y php-fpm php-cli php-mysql composer

              # Clone your Laravel app from a Git repository
              git clone https://github.com/your-laravel-repo.git /var/www/laravel-app
              cd /var/www/laravel-app
              composer install

              # Install Node.js and npm for Angular
              curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
              apt-get install -y nodejs
              npm install -g @angular/cli

              # Clone your Angular app from a Git repository
              git clone https://github.com/your-angular-repo.git /var/www/angular-app
              cd /var/www/angular-app
              npm install

              # Configure Nginx to serve Laravel and Angular apps
              cat > /etc/nginx/sites-available/laravel-angular <<EOL
              server {
                  listen 80;
                  server_name alparslan.com;

                  location /laravel {
                      alias /var/www/laravel-app/public;
                      try_files $uri $uri/ /laravel/index.php?$query_string;
                  }

                  location /angular {
                      alias /var/www/angular-app/dist/angular-app;
                      try_files $uri $uri/ /angular/index.html;
                  }

                  location / {
                      root /var/www;
                  }
              }
              EOL
              ln -s /etc/nginx/sites-available/laravel-angular /etc/nginx/sites-enabled/
              nginx -t
              systemctl reload nginx
              EOF
}

# Output the Load Balancer IP
output "load_balancer_ip" {
  value = digitalocean_loadbalancer.alparslan_lb.ip
}