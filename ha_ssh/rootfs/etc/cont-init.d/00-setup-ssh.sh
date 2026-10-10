#!/usr/bin/with-contenv bashio

AUTHORIZED_KEY=$(bashio::config 'ssh_authorized_key')
if [ -z "${AUTHORIZED_KEY}" ]; then
    bashio::log.error "ssh_authorized_key vazio, o SSH não será iniciado."
    exit 0
fi

SSH_KEYS_DIR="/data/ssh_host_keys"
mkdir -p "${SSH_KEYS_DIR}"
chmod 700 "${SSH_KEYS_DIR}"

for type in rsa ed25519; do
    key="${SSH_KEYS_DIR}/ssh_host_${type}_key"
    if [ ! -f "${key}" ]; then
        ssh-keygen -t "${type}" -f "${key}" -N "" -q
    fi
done

mkdir -p /root/.ssh
chmod 700 /root/.ssh
printf '%s\n' "${AUTHORIZED_KEY}" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

SUP_TOKEN="${SUPERVISOR_TOKEN:-}"
if [ -z "${SUP_TOKEN}" ] && [ -r /run/s6/container_environment/SUPERVISOR_TOKEN ]; then
    SUP_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN)
fi
{
    printf 'SUPERVISOR_TOKEN=%s\n' "${SUP_TOKEN}"
    printf 'HASSIO_TOKEN=%s\n' "${SUP_TOKEN}"
} > /root/.ssh/environment
chmod 600 /root/.ssh/environment

SSH_PORT=$(bashio::config 'ssh_port')

mkdir -p /etc/ssh
cat > /etc/ssh/sshd_config << EOT
Port ${SSH_PORT}
HostKey ${SSH_KEYS_DIR}/ssh_host_rsa_key
HostKey ${SSH_KEYS_DIR}/ssh_host_ed25519_key
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitUserEnvironment yes
PrintMotd no
Subsystem sftp internal-sftp
EOT

touch /run/ha_ssh_enabled
bashio::log.info "SSH configurado na porta ${SSH_PORT} (root, somente chave pública)."
