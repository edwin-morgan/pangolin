module SparqlQueries
  require 'sparql/client'

  def make_query(key,value)
    # set the sparql endpoint
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
    # params value has underscores, so replace them with spaces
    value.gsub!("_"," ")
    # the query hash below contains the sparql queries;
    # and the basic idea was that its keys can broadly match
    # the params keys permitted in MoviesController
    query = {
      actor: %Q[
        SELECT DISTINCT ?actor ?name ?starring ?title WHERE {
          {
            SELECT ?actor ?name WHERE {
            ?actor a dbo:Person.
            ?actor dct:description ?y .
            FILTER regex(?y, "actor|actress", "i").
            ?actor foaf:name "#{value}"@en.
            ?actor foaf:name ?name.
            ?film dbo:occupation ?occ.
            }
          }
        ?starring dbo:starring ?actor.
        ?starring foaf:name ?title.
        }
        ORDER BY strlen(str(?name))
      ],
      film: %Q[
        SELECT ?film ?starring ?title ?actors WHERE {
          {
            SELECT ?film ?starring WHERE {
            ?film a dbo:Film.
            ?film rdfs:label ?y .
            ?film foaf:name "#{value}"@en.
            ?film dbo:starring ?starring.
            }
          }
        ?starring foaf:name ?actors.
        ?film foaf:name ?title.
        }
        ORDER BY strlen(str(?title))
      ],
      film_slow_query: %Q[
        SELECT ?film ?starring ?title ?actors WHERE {
          {
            SELECT ?film ?starring WHERE {
            ?film a dbo:Film.
            ?film rdfs:label ?y .
            FILTER regex(?y, "#{value}", "i").
            ?film dbo:starring ?starring.
            }
          }
        ?starring foaf:name ?actors.
        ?film foaf:name ?title.
        }
        ORDER BY strlen(str(?title))
      ]
    }
    # make the query - here query[key] references the correct
    # sparql query from above, based on the params key sent
    results = sparql.query(query[key]) do |result|
      result.inspect
    end
    # searching for film by name is unreliable, so in case of no initial results:
    if results.empty? && key == :film
      results = sparql.query(query[:film_slow_query]) do |result|
        result.inspect
      end
    end
    # reorganise the results to make more readable
    data = {}
    if key == :film
      results.map! { |el| { title: el.title.to_s, actor: el.actors.to_s } }.
              each do |v|
                if data[v[:title]].present?
                  data[v[:title]][:actors] << v[:actor] unless data[v[:title]][:actors].include?(v[:actor])
                else
                  data[v[:title]] = { actors: [v[:actor]] }
                end
              end
    elsif key == :actor
      results.map! { |el| {name: el.name.to_s, title: el.title.to_s } }.
              each do |v|
                if data[v[:name]]
                  data[v[:name]][:films] << v[:title]
                else
                  data[v[:name]] = {films: [v[:title]] }
                end
              end
    end
    # return an error message if no results found
    data = { error: "No results for #{key.to_s}: #{value}" } if data.empty?
    # return the data
    data
  end

end
