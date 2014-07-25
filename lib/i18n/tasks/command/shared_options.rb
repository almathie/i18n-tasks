module I18n::Tasks
  module Command
    module SharedOptions

      def self.included(base)
        base.extend KlassMethods
      end

      module KlassMethods
        def common_option_definitions
          {
              strict:        {
                  short: :s,
                  long:  :strict,
                  desc:  %Q(Do not infer dynamic key usage such as `t("category.\#{category.name}")`)
              },
              stdin:         {
                  short: :s,
                  long:  :stdin,
                  desc:  'Read locale data from stdin before the arguments'
              },
              pattern:       {
                  short: :p,
                  long:  :pattern=,
                  desc:  %(Filter by key pattern (e.g. 'common.*')),
                  conf:  {argument: true, optional: false}
              },
              missing_types: {
                  short: :t,
                  long:  :types=,
                  desc:  'Filter by type (types: used, diff)', conf: {as: Array, delimiter: /[+:,]/}
              },
              value:         {
                  short: :v,
                  long:  :value=,
                  desc:  'Value, interpolates %{value}, %{human_key}, and %{value_or_human_key}',
                  conf:  {argument: true, optional: false}
              }
          }
        end
      end
    end
  end
end
