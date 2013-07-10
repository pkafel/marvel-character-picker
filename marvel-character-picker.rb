require "rexml/document"
require "net/http"
require "uri"

module Constants
  BASE_URI = "http://en.wikipedia.org/w/api.php?"

  HERO_URI = "http://en.wikipedia.org/wiki?curid="

  HEROES_XPATH = "api/query/categorymembers"

  BASE_URI_PARAMS = {:action => "query",
                     :list => "categorymembers",
                     :format => "xml",
                     :cmtitle => "Category%3AMarvel_Comics_superheroes",
                     :cmsort => "sortkey",
                     :titles => "Category%3AMarvel_Comics_superheroes"}

  MAX_NUMBER_OF_RETRY=3
end

class RandomMarvelHeroPicker

  include Constants

  def pick_random_hero
    begin
      and_the_winner_is pick_hero
    rescue Exception => details
      picking_failed_because_of details
    end
  end

  private

  def and_the_winner_is(hero)
    puts "----------"
    puts "And the winner is..."
    sleep 3
    puts "Name: #{hero.attributes['title']}"
    puts "Wiki link: #{HERO_URI}#{hero.attributes['pageid']}"
    puts "----------"
  end

  def picking_failed_because_of(reason)
    puts "Sorry but I cannot pick a hero for you..."
    puts "Reason: #{reason}"
  end

  def pick_hero
    retry_number=0
    while true
      begin
        return try_to_pick_hero()
      rescue ArgumentError
        retry_number+=1
        raise "Maximum number of retries has been used" if retry_number>MAX_NUMBER_OF_RETRY
      end
    end
  end

  def try_to_pick_hero
    hero_first_letter=Random.new.rand(65..90).chr.to_s
    url = construct_url_for hero_first_letter
    heroes_list = get_heroes_list_under url
    random_element_from heroes_list
  end

  def construct_url_for(letter)
    params = BASE_URI_PARAMS.clone
    params[:cmstartsortkeyprefix] = letter
    params[:cmendsortkeyprefix] = letter.succ if letter == 'Z'
    BASE_URI + params.map { |k, v| "#{k}=#{v}" }.join('&')
  end

  def get_heroes_list_under(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    raise "Retrieve a #{response.code} from server !" unless response.code!=200
    doc = REXML::Document.new response.body
    doc.elements[HEROES_XPATH]
  end

  def random_element_from(heroes_list)
    raise ArgumentError, "Empty heroes list !" unless heroes_list.length!=0
    hero_index = Random.new.rand(0..heroes_list.length-1)
    heroes_list[hero_index]
  end
end

# Main
RandomMarvelHeroPicker.new.pick_random_hero