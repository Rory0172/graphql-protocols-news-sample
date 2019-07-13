require "sinatra/base"
require "graphql"

module Messages
  def messages
    [{message: "You are all breathtaking!"}]
  end

  module Mutations
    def sendMessage
      {message: "No! YOU are breathtaking!"}
    end
  end
end

module Posts
  def posts
    [
      {
        title: "Keanu Reeves", 
        markdownContent: "Keanu Charles Reeves born September 2, 1964) is a Canadian[a] actor and musician. He gained fame for his starring roles in several blockbuster films, including comedies from the Bill and Ted franchise (1989–2020); action thrillers Point Break (1991), Speed (1994), the John Wick franchise (2014–2021); psychological thriller The Devil's Advocate (1997); supernatural thriller Constantine (2005); and science fiction/action series The Matrix (1999–2003). He has also appeared in dramatic films such as Dangerous Liaisons (1988), My Own Private Idaho (1991), and Little Buddha (1993), as well as the romantic horror Bram Stoker's Dracula (1992).", 
        link:"google.nl",
        tags: ["acting", "bikes", "awesome"]
      },
      {
        title: "Jason Momoa",
        markdownContent: "Joseph Jason Namakaeha Momoa (born August 1, 1979) is an American actor. He played Aquaman in the DC Extended Universe, beginning with the 2016 superhero film Batman v Superman: Dawn of Justice, and in the 2017 ensemble Justice League and his 2018 solo film Aquaman. In Baywatch Hawaii, he portrayed Lifeguard Jason Ioane.[1][2] On television, he played Ronon Dex on the military science fiction television series Stargate Atlantis (2004–2009), Khal Drogo in the HBO fantasy television series Game of Thrones (2011–2019, although he only featured in the first season), and Declan Harp in the CBC series Frontier (2016–present).",
        link: "https://en.wikipedia.org/wiki/Jason_Momoa",
        tags: ["acting", "Hawaii", "Got"]
      }
    ]
  end
end

class Query
  include Messages
  include Posts
  def viewer
    nil
  end
end

class Mutation
  include Messages::Mutations
end

module TestAPI
  module Resolver
    def self.call(type, field, obj, args, ctx)
      s = field.name.to_sym
      case type.to_s
      when 'Mutation'
        x = Mutation.new
        x.public_send(s)

      when 'Query'
        x = Query.new
        x.public_send(s)
      else
        return obj[s] if obj.is_a? Hash
        obj.public_send(s)
      end
    end
  end

  class App < Sinatra::Base
    post "/graphql" do
      body = JSON.parse(request.body.read)
      variables = body["variables"]
      query = body["query"]
      operation_name = body["operationName"]
      context = {}

      schema = Dir["#{File.dirname(__FILE__)}/protocols/**/*.graphql","#{File.dirname(__FILE__)}/graphql/schema.graphql"].map { |x|  File.read(x) }.join      

      puts schema

      built_schema = GraphQL::Schema.from_definition(schema, default_resolve: Resolver)
      result = built_schema.execute(query, variables: variables, context: context, operation_name: operation_name)
      content_type :json 
      result.to_json
    end
  end
end
