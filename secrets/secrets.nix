let
  alice_machine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJDyIr/FSz1cJdcoW69R+NrWzwGK/+3gJpqD1t8L2zE";
  systems = [ alice_machine ];
in
{
  "backblaze-account-id.age".publicKeys = systems;
  "backblaze-account-key.age".publicKeys = systems;
}