# frozen_string_literal: true

require "single_cov"
SingleCov.setup :minitest

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "myway_config"

require "minitest/autorun"
