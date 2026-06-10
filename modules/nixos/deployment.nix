{
  config,
  ...
}:
{
  config.deployment = {
    targetUser = null;
    buildOnTarget = builtins.elem "cloudlab" config.deployment.tags;
    allowLocalDeployment = builtins.elem "personal" config.deployment.tags;
  };
}
