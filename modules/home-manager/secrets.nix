{ ... }:
{
  # Home Manager agenix configuration
  age.identityPaths = [ "/home/nicolas/.ssh/id_ed25519" ];

  age.secrets = {
    backblaze-account-id = {
      file = ../../secrets/backblaze-account-id.age;
    };
    
    backblaze-account-key = {
      file = ../../secrets/backblaze-account-key.age;
    };
  };
}
