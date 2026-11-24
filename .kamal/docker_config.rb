require "sshkit"

# Each CI deployment authenticates to GHCR with its own short-lived token.
if ENV["GITHUB_ACTIONS"] == "true"
  SSHKit.config.default_env[:docker_config] = "$HOME/.docker/kamal-chez-maurice-production"
end
