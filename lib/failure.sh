warnings=$(mktemp -t scalingo-buildpack-nodejs-XXXX)

failure_message() {
  local warn="$(cat $warnings)"
  echo ""
  echo "We're sorry this build is failing!"
  echo ""
  if [ "$warn" != "" ]; then
    echo "Some possible problems:"
    echo ""
    echo "$warn"
  else
    echo "If you're stuck, please send us an email so we can help:"
    echo "support@scalingo.com"
  fi
  echo ""
  echo "Keep coding,"
  echo "Scalingo"
  echo ""
}

fail_invalid_package_json() {
  if ! cat ${1:-}/package.json | $JQ "." 1>/dev/null; then
    error "Unable to parse package.json"
    return 1
  fi
}

warning() {
  local tip=${1:-}
  local url=${2:-http://doc.scalingo.com/languages/javascript/nodejs}
  echo "- $tip" >> $warnings
  echo "  $url" >> $warnings
  echo "" >> $warnings
}

warn_node_engine() {
  local node_engine=${1:-}
  if [ "$node_engine" == "" ]; then
    warning "Node version not specified in package.json" "http://doc.scalingo.com/languages/javascript/nodejs#specifying-a-nodejs-version"
  elif [ "$node_engine" == "*" ]; then
    warning "Dangerous semver range (*) in engines.node" "http://doc.scalingo.com/languages/javascript/nodejs#specifying-a-nodejs-version"
  elif [ ${node_engine:0:1} == ">" ]; then
    warning "Dangerous semver range (>) in engines.node" "http://doc.scalingo.com/languages/javascript/nodejs#specifying-a-nodejs-version"
  fi
}

warn_prebuilt_modules() {
  local build_dir=${1:-}
  if [ -e "$build_dir/node_modules" ]; then
    warning "node_modules checked into source control" "https://docs.npmjs.com/misc/faq#should-i-check-my-node-modules-folder-into-git"
  fi
}

warn_missing_package_json() {
  local build_dir=${1:-}
  if ! [ -e "$build_dir/package.json" ]; then
    warning "No package.json found"
  fi
}

warn_old_npm() {
  local npm_version="$(npm --version)"
  if [ "${npm_version:0:1}" -lt "2" ]; then
    local latest_npm="$(curl --silent --get https://semver.scalingo.io/npm/stable)"
    warning "This version of npm ($npm_version) has several known issues - consider upgrading to the latest release ($latest_npm)" "http://doc.scalingo.com/languages/javascript/nodejs#specifying-a-nodejs-version"
  fi
}

warn_meteor_npm_dir() {
  if [ ! -d "packages/npm-container" ] ; then
    warning "Your Meteor app is using '${meteorhacks_npm_version}', check in the 'packages/npm-container' directory in your GIT repository" "http://doc.scalingo.com/languages/javascript/nodejs/meteor/npm"
  fi
}

warn_meteor_npm_packages_json() {
  if [ ! -e "packages.json" ] ; then
    warning "Your Meteor app is using '${meteorhacks_npm_version}', check in 'packages.json' in your GIT repository" "http://doc.scalingo.com/languages/javascript/nodejs/meteor/npm"
  fi
}

warn_meteor_npm_package() {
  if ! grep -q npm-container ".meteor/packages" ; then
    warning "Your Meteor app is using '${meteorhacks_npm_version}', add 'npm-container' in '.meteor/packages'" "http://doc.scalingo.com/languages/javascript/nodejs/meteor/npm"
  fi
}

warn_untracked_dependencies() {
  local log_file="$1"
  if grep -qi 'gulp: not found' "$log_file"; then
    warning "Gulp may not be tracked in package.json" "https://devcenter.heroku.com/articles/troubleshooting-node-deploys#ensure-you-aren-t-relying-on-untracked-dependencies"
  fi
  if grep -qi 'grunt: not found' "$log_file"; then
    warning "Grunt may not be tracked in package.json" "https://devcenter.heroku.com/articles/troubleshooting-node-deploys#ensure-you-aren-t-relying-on-untracked-dependencies"
  fi
  if grep -qi 'bower: not found' "$log_file"; then
    warning "Bower may not be tracked in package.json" "https://devcenter.heroku.com/articles/troubleshooting-node-deploys#ensure-you-aren-t-relying-on-untracked-dependencies"
  fi
}

warn_angular_resolution() {
  local log_file="$1"
  if grep -qi 'Unable to find suitable version for angular' "$log_file"; then
    warning "Bower may need a resolution hint for angular" "https://github.com/bower/bower/issues/1746"
  fi
}
