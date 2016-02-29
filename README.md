LHS
===

LHS uses [LHC](//github.com/local-ch/LHC) for http requests.

## Very Short Introduction

A LHS::Record makes data available using backend services and one or multiple endpoints.

```ruby
class Feedback < LHS::Record

  endpoint ':datastore/v2/content-ads/:campaign_id/feedbacks'
  endpoint ':datastore/v2/feedbacks'

end

feedback = Feedback.find_by_email('somebody@mail.com') #<Feedback>
feedback.review # "Lunch was great"
```

## Where to store LHS::Records

Please store all defined LHS::Records in `app/models` as they are not autoloaded by rails otherwise.

## Endpoints

You setup a LHS::Record by configuring one or multiple backend endpoints. You can also add request options for an endpoint (see following example).

```ruby
class Feedback < LHS::Record

  endpoint ':datastore/v2/content-ads/:campaign_id/feedbacks'
  endpoint ':datastore/v2/content-ads/:campaign_id/feedbacks/:id'
  endpoint ':datastore/v2/feedbacks', cache: true, cache_expires_in: 1.day
  endpoint ':datastore/v2/feedbacks/:id', cache: true, cache_expires_in: 1.day

end
```

If you try to setup a LHS::Record with clashing endpoints it will immediately raise an exception.

```ruby
class Feedback < LHS::Record

  endpoint ':datastore/v2/reviews'
  endpoint ':datastore/v2/feedbacks'

end
# raises: Clashing endpoints.
```

## Find multiple records

You can query a backend service to provide records by using `where`.

```ruby
  Feedback.where(has_reviews: true)
```

This uses the `:datastore/v2/feedbacks` endpoint, cause `:campaign_id` was not provided. In addition it would add `?has_reviews=true` to the get parameters.

```ruby
  Feedback.where(campaign_id: 'fq-a81ngsl1d')
```

Uses the `:datastore/v2/content-ads/:campaign_id/feedbacks` endpoint.

## Find single records

`find` finds a unique record by uniqe identifier (usualy id).

If no record is found an error is raised.

## Proxy
Instead of mapping data when it arrives from the backend, the proxy makes data accessible when you access it, not when you fetch it. The proxy is used to access data and it is divided in `Collection` and `Item`. 

`find` can also be used to find a single uniqe record with parameters:

```ruby
  Feedback.find(campaign_id: 123, id: 456)
```

`find_by` finds the first record matching the specified conditions.

If no record is found, `nil` is returned.

`find_by!` raises LHC::NotFound if nothing was found.

```ruby
  Feedback.find_by(id: 'z12f-3asm3ngals')
  Feedback.find_by(id: 'doesntexist') # nil
```

`first` is an alias for finding the first record without parameters.

```ruby
  Feedback.first
```

If no record is found, `nil` is returned.

`first!` raises LHC::NotFound if nothing was found.

## Batch processing

**Be carefull using methods for batch processing. They could result in a lot of HTTP requests!**

`all` fetches all records from the backend by doing multiple requests if necessary.

```ruby
data = Feedback.all
data.count # 998
data.total # 998
```

`find_each` is a more fine grained way to process single records that are fetched in batches.

```ruby
Feedback.find_each(start: 50, batch_size: 20, params: { has_reviews: true }) do |feedback|
  # Iterates over each record. Starts with record nr. 50 and fetches 20 records each batch.
  feedback 
  break if feedback.some_attribute == some_value
end
```

`find_in_batches` is used by `find_each` and processes batches.
```ruby
Feedback.find_in_batches(start: 50, batch_size: 20, params: { has_reviews: true }) do |feedbacks|
  # Iterates over multiple records (batch size is 20). Starts with record nr. 50 and fetches 20 records each batch.
  feedbacks
  break if feedback.some_attribute == some_value
end
```

## Create records

```ruby
  feedback = Feedback.create(
    recommended: true,
    source_id: 'aaa',
    content_ad_id: '1z-5r1fkaj'
  )
```

When creation fails, the object contains errors. It provides them through the `errors` attribute:

```ruby
  feedback.errors #<LHS::Errors>
  feedback.errors.include?(:ratings) # true
  feedback.errors[:ratings] # ['REQUIRED_PROPERTY_VALUE']
  record.errors.messages # {:ratings=>["REQUIRED_PROPERTY_VALUE"], :recommended=>["REQUIRED_PROPERTY_VALUE"]}
  record.errors.message # ratings must be set when review or name or review_title is set | The property value is required; it cannot be null, empty, or blank."
```

## Build new records

Build and persist new items from scratch are done either with `new` or it's alias `build`.

```ruby
  feedback = Feedback.new(recommended: true)
  feedback.save
```

## Include linked resources

When fetching records, you can specify in advance all the linked resources that you want to include in the results. With `includes`, LHS ensures that all matching and explicitly linked resources are loaded and merged.

The implementation is heavily influenced by [http://guides.rubyonrails.org/active_record_class_querying](http://guides.rubyonrails.org/active_record_class_querying.html#eager-loading-associations) and you should read it to understand this feature in all its glory.

### One-Level `includes`

```ruby
  # a claim has a localch_account
  claims = Claims.includes(:localch_account).where(place_id: 'huU90mB_6vAfUdVz_uDoyA')
  claims.first.localch_account.email # 'test@email.com'
```
* [see the JSON without include](examples/claim_no_include.json)
* [see the JSON with include](examples/claim_with_include.json)

### Two-Level `includes`

```ruby
  # a feedback has a campaign, which has an entry
  feedbacks = Feedback.includes(campaign: :entry).where(has_reviews: true)
  feedbacks.first.campaign.entry.name # 'Casa Ferlin'
```

### Multiple `includes`

```ruby
  # list of includes
  claims = Claims.includes(:localch_account, :entry).where(place_id: 'huU90mB_6vAfUdVz_uDoyA')
  
  # array of includes
  claims = Claims.includes([:localch_account, :entry]).where(place_id: 'huU90mB_6vAfUdVz_uDoyA')
  
  # Two-level with array of includes
  feedbacks = Feedback.includes(campaign: [:entry, :user]).where(has_reviews: true)
```

### Known LHS::Records are used to request linked resources

When including linked resources with `includes`, known/defined services and endpoints are used to make those requests. 
That also means that options for endpoints of linked resources are applied when requesting those in addition.
This allows you to include protected resources (e.g. OAuth) as endpoint options for oauth authentication get applied.

The [Auth Inteceptor](https://github.com/local-ch/lhc-core-interceptors#auth-interceptor) from [lhc-core-interceptors](https://github.com/local-ch/lhc-core-interceptors) is used to configure the following endpoints.

```ruby
class Favorite < LHS::Record

  endpoint ':datastore/:user_id/favorites', auth: { bearer: -> { bearer_token } }
  endpoint ':datastore/:user_id/favorites/:id', auth: { bearer: -> { bearer_token } }

end

class Place < LHS::Record

  endpoint ':datastore/v2/places', auth: { bearer: -> { bearer_token } }
  endpoint ':datastore/v2/places/:id', auth: { bearer: -> { bearer_token } }

end

Favorite.includes(:place).where(user_id: current_user.id) 
# Will include places and applies endpoint options to authenticate the request.
```

## Map data

To influence how data is accessed/provied, you can use mappings to either map deep nested data or to manipulate data when its accessed. Simply create methods inside the LHS::Record. They can access underlying data:

```ruby
class LocalEntry < LHS::Record
  endpoint ':datastore/v2/local-entries'

  def name
    addresses.first.business.identities.first.name
  end

end
```

### Known LHS::Records when accessing mapped data from nested data

As LHS detects LHS::Records as soon as a link is present, mappings will also be applied on nested data:

```
class Place < LHS::Record
  endpoint ':datastore/v2/places'

  def name
    addresses.first.business.identities.first.name
  end
end

class Favorite < LHS::Record
  endpoint ':datastore/v2/favorites'
end

favorite = Favorite.includes(:place).find(1)
favorite.place.name # local.ch AG
```

## Setters

You can change attributes of LHS::Records:

```
  record = Feedback.find(id: 'z12f-3asm3ngals')
  rcord.recommended = false
```

## Save

You can persist changes with `save`. `save` will return `false` if persisting fails. `save!` instead will raise an exception.

```ruby
  feedback = Feedback.find('1z-5r1fkaj')
  feedback.recommended = false
  feedback.save
```

## Update

`update` will return false if persisting fails. `update!` instead will an raise exception.

`update` always updates the data of the local object first, before it tries to sync with an endpoint. So even if persisting fails, the local object is updated.

```ruby
feedback = Feedback.find('1z-5r1fkaj')
feedback.update(recommended: false)
```

## Destroy

You can delete records remotely by calling `destroy` on an LHS::Record.

```ruby
  feedback = Feedback.find('1z-5r1fkaj')
  feedback.destroy
```

## Validation

In order to validate LHS::Records before persisting them, you can use the `valid?` (`validate` alias) method.

The specific endpoint has to support validations with the `persist=false` parameter. The endpoint has to be enabled (opt-in) for validations in the service configuration.

```
class User < LHS::Record
  endpoint ':datastore/v2/users', validates: true
end

user = User.build(email: 'im not an email address')
unless user.valid?
  fail(user.errors[:email])
end
```

## Collections: Offset / Limit / Pagination

You can paginate by passing offset, and limit params. They will be forwarded to the backend.

```ruby
data = Feedback.where(limit: 50)
data.count // 50
Feedback.where(limit: 50, offset: 51)
```

`total` provides total amount of items (even if paginated).
`limit` provides amount of items per page.
`offset` provides how many items where skipped to start the current page.

## Partial Kaminari support

LHS implements an interface that makes it partially working with Kaminari.

For example, you can use kaminari to render paginations based on LHS Records:

```ruby
# controller
@items = Record.where(offset: offset, limit: limit)
```

```ruby
# view
= paginate @items
```

## form_for Helper
Rails `form_for` view-helper can be used in combination with instances of LHS::Record to autogenerate forms:
```
<%= form_for(@instance, url: '/create') do |f| %>
  <%= f.text_field :name %>
  <%= f.text_area :text %>
  <%= f.submit "Create" %>
<% end %>
```
