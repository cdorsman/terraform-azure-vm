#cloud-config
users:
  - name: ${admin_username}
    ssh-authorized-keys:
%{ for key in keys ~}
      - ${key}
%{ endfor }
