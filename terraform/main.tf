terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}
variable "GHTOKEN" {
  # pass as TF_VAR_GHTOKEN="mystring"
  type = string
}
# Configure the GitHub Provider
provider "github" {
  token = var.GHTOKEN
}
# create repo
# import existing ones with `terraform import github_repository.reponame reponame`
resource "github_repository" "repo" {
  name        = "example"
  description = "My awesome codebase"
  visibility = "private"
  auto_init = true
}
# create branch
resource "github_branch" "main" {
  repository = github_repository.repo.name
  branch = "main"
}
# and set as default
resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch = github_branch.main.branch
}
# create a deploy-key for the pipeline
resource "github_repository_deploy_key" "deploy-key" {
  title = "deploy key"
  repository = github_repository.repo.name
  key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQC0mnL3coZoBmCntBlZ4pZkByQ+9yi4UFLHLsLikw/DDu/LC4nK/LrsI60lZkZYWS++bKkpSWSGYhP2Vs4EscVyEFULrvAWdpFA95RmyXYOMQ4tPxk8llvl/nFtIYX48btqnzfO6Uy46jf9G/SxFlDUHBTDtQcuB/Y6d+Yxf7DhJlEM4r6TavRZrehixvqWZUz2plO+7xHYTTZzhoIQK6+3VsVMJlN2N9/zjrqqW/HYnjzJElprTWm9Q2bSd1lEOz8v0KyKsaOvyNrjY6DLRV6bvJLlooLjKPAUpf7SQ7nXqDLjit2EixOkcYxIRM0K0A/futNs0i1BsggOIGx4NbCNJs2DQaXaxLYX5JaLJQ08WI+QIboAA0TS8XEag+JdUnN1NbrnXgnmfVWXD/x3krn4rzFpjjGxBhtQsPRuXb+ESwnaIJFqea0FNGma1sr2/H83muyjoNTDiRdEGji3dsuMyJ/bP59ibn9Rf4zERkEnT6Gk9gnG5dFvfDC7QcOxThqK2VGE4aPu5BGc8CD7YA2wYP5m4e+yLBPzmQVyrYtbqoDnyGAUgJAcooQH+nh5KysANWNkh6JYRdYjRl7tOdnozmC+6HvSCsQhTYDQy0WwHqwc/3wCdMfP5VLpIkld/CTNgyA6ATT2RO1MwDc/zGv3ycCs/sKcJN+JYHXUttlZEiSlXYYxal8pDeUd+zeQCmAmVOCRbuh+DXfJcDpZGphdMM9YerVfVTdaybnuKI/dJ0BknjLFKpJRRvcygCqF2xrLiy1gUc3BBXMzjlQ6N91sCagpqJtWHgvawMly0sAkamTXx60JjX636Id3jfRISz5yuyC6tgds5gqdnMKLZ9f/jSp1vxAGAjgVEftHKh+++StoKyr2YubMbKaOiItprJXwknZ3GgAIIJqwQm4rKkRlA19UH6fojCsCgdAaOS9BQ5gtNF7UZqM9pZXB5NwEZG0awUWz/a2Snp92txCUvnRDd9CkQWGYN18lxetqq/mY3m8CI/cQ1xruyazFDs7lLpMtZS/yT8bsc8XRHzGs/IfZzPoMcejSKrf8ThGiOdXaE8XBMXOQrL9M60oUrNXzc9XCQLtQW0ocwkt7axvogSS0Q8cv239+SXWjzpkJF/cBsdNwq+nf6/SKlKR7fr61m8hg80yt5+iMpxJxmqvNzVHEGb6H01XlnwJxBjdmvsC8m8cT4kAPirnZcoVDiRAwT1s51H+52jaZMhD2yA9OgBuhMXT8WjG/r1hwJp0kiHd/bua26qtiq+gH+hQgAFelixGidOcfvRRnk3u4RSMNADM6MB/7MJCmOKbOZEsp9238W0De/B915e4TJ6HeujS/qzdgWpFV4PQADymPK95a8emT root@kane.opviel.de"
  read_only = false
}
