project_id            = "${{ values.project_id }}"
region                = "${{ values.region }}"
service_name          = "${{ values.service_name }}"
image                 = "${{ values.image }}"
service_account_email = "${{ values.service_account_email }}"

container_port        = ${{ values.container_port }}
min_instance_count    = ${{ values.min_instance_count }}
max_instance_count    = ${{ values.max_instance_count }}
cpu                   = "${{ values.cpu }}"
memory                = "${{ values.memory }}"
ingress               = "${{ values.ingress }}"
allow_unauthenticated = ${{ values.allow_unauthenticated }}

env_vars = {
  ENVIRONMENT = "${{ values.environment }}"
  PLATFORM    = "paved-road-platform"
}

labels = {
  environment = "${{ values.environment }}"
  managed_by  = "backstage"
  platform    = "paved-road-platform"
  security    = "hardened"
}
