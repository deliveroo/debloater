# debloater

Safely rebuilds PostgreSQL indices on a live database.


## Installation

With a recent version of Ruby installed, run:

    gem install debloater


## Usage

If you run `debloater` without arguments, you should read:

```
Usage: debloater [options] database
    -h HOST                          Database host to connect to [localhost]
    -p PORT                          Port to connect to [5432]
    -U USER                          Username to connect with [postgres]
    -W                               Prompt for password (default)
    -w                               No prompt for password
        --auto                       Do not ask for confirmation before debloating
        --min-mb [SIZE]              Do not debloat if the bloat size is lower than SIZE megabytes [50]
        --max-density [FRACTION]     Do not debloat if the index density is higher than FRACTION [0.75]
        --help                       Prints this help
```

### Caveats

The `pgstattuple` extension is required; install it if asked with:

```sql
CREATE EXTENSION pgstattuple;
```

Within this extension, permission to run `pgstatindex()` is required; this may
be problematic on some platforms, e.g. Amazon RDS. `debloater` will fall back to
a function called `get_pgstatindex()` with the same profile, which you can
create with the following script (run as an administrator):

```sql
CREATE OR REPLACE FUNCTION get_pgstatindex(
      relname             regclass,
  OUT index_size          bigint,
  OUT avg_leaf_density    float8,
  OUT leaf_fragmentation  float8
)
AS $$
BEGIN
  SELECT i.index_size, i.avg_leaf_density, i.leaf_fragmentation
  FROM pgstatindex(relname) i
  INTO index_size, avg_leaf_density, leaf_fragmentation;
END;
$$ LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER;
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deliveroo/debloater.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

