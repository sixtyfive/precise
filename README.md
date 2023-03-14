## Command line usage

Install the gem and see the help message by executing:

    $ gem install precise
    $ precise -h

Arabicise a string of Romanisation:

    $ precise -T 'bi-smi llāhi al-raḥmani al-raḥīm' # -T removes Tashkeel

Romanise a string of Arabic (experimental):

    $ precise 'بسم  الله الرحمن الرحيم' # (not able to infer Tashkeel!)

## Usage inside of another application

Install the gem and add to the application's Gemfile by executing:

    $ bundle add precise
    $ bundle install

You can then access the API like so:

```ruby
require 'precise'
Precise::Transcription.reverse 'bi-smi llāhi al-raḥmani al-raḥīm'
Precise::Transcription.transcribe 'ﺐﺴﻣ  ﺎﻠﻠﻫ ﺎﻟﺮﺤﻤﻧ ﺎﻟﺮﺤﻴﻣ'
```

## Development

After checking out the repository, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Issues and PRs are welcome!

## Funding

This Gem was developed within the long-term research project [Bibliotheca Arabica](http://www.bibliotheca-arabica.de) hosted at the Saxon Academy of the Sciences and Humanities in Leipzig, Germany. _Bibliotheca Arabica_ is part of the [German Academies’ Programme](https://www.akademienunion.de/en/research/the-academies-programme) and funded by the Federal Republic of Germany and the Free State of Saxony.
