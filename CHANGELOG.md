##### Changelog v2.0.1 30/01/2017:

- New attribute `default["war"]["url_bbi"]` to manage BBI's deployments.

- Resource `log 'Eva.war downloaded.'` changed to `log "Eva.war downloaded from #{$war_url}"` in `deploy_proc.rb` recipe.

##### Changelog v2.0.0 24/01/2017:

- Global varibles `node_name`, `war_folder`, `username`, `password` and `war_url` were added to avoid redundance.

- Delete and replace some varibles to improve the cookbook's workflow.

- Delete `ruby_block Stop Eva (reverse)` resource in `reverse.rb` recipe to avoid unnecessary actions that cause Timeout errors.

- The last two dates of the changelog was corrected.

##### Changelog v1.2.7 20/01/2017:

- New attribute `default["war"]["url_panama"]` to manage Panamá's deployments.

- Varible `war_url` in `deploy_proc.rb` recipe stores the current url to download `Eva.war`.

##### Changelog v1.2.6 20/10/2016:

- Delete `ruby_block Stop Eva (manager)` resource in `deploy_proc.rb` recipe to avoid unnecessary actions that cause Timeout errors.

- Improve logic of `undeploy` function in `Eva` module.

##### Changelog v1.2.5 18/10/2016:

- Add new method in module `Tools` to fetch JSON data from an URL.

- Use `fetch` method in `ruby_block "Verify deployment"` resource of `deploy_proc.rb` and `reverse.rb` recipe to get data from `Eva/apilocalidad/version` service.

- Add varibles `node_name` and `prefix` in `deploy_proc.rb` and `reverse.rb` recipe to determine the company of shop updated when email is sent by `ruby_block "Verify deployment"` resource.

##### Changelog v1.2.4 11/10/2016:

- Add ruby_block resource in `prepare.rb` recipe to send a simple email when update process start in the nodes.

- `undeploy` change from method to function in module `Eva`, if undeploy Eva return true.

- Add resources to delete Eva.war and Eva folder in `deploy_proc.rb` recipe if undeploy fail for second time.
