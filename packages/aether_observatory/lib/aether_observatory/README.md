# AetherObservatory Guide

In this guide we are going to walk through example code to illustrate the usage of the `AetherObservatory::`. When finished you will have a class to create events and a class that subscribes to those events.

#### Table of Contents
- [Creating Events](#creating-events)
- [Creating an Observer and Subscribing to Events](#creating-an-observer-and-subscribing-to-events)
- [Sending an Event to your Observer](#sending-an-event-to-your-observer)
- [Stopping Observers](#stopping-observers)
- [Using Dynamic Event Names](#using-dynamic-event-names)
- [Multiple Event Topics](#multiple-event-topics)

## Creating Events

To begin create an `ApplicationEvent` class that extends the `AetherObservatory::EventBase` class. Next configure a prefix for event names using `event_prefix`. This is optional, but encouraged to help prevent naming collisions with other domains. Every domain event we define as a sub-class to the `ApplicationEvent` will inherit this prefix.

```ruby
module AetherObservatory
  module Examples
    class ApplicationEvent < AetherObservatory::EventBase
      event_prefix 'talkbox'
    end
  end
end
```

Next we create an event class called `ExampleEvent` that extends our `ApplicationEvent`. In this class we define the topic we would like our event sent to using the `event_name` method. Lastly we will define our data using the `attribute` method.

```ruby
module AetherObservatory
  module Examples
    class ExampleEvent < AetherObservatory::Examples::ApplicationEvent
      event_name 'example1'

      attribute :message
      attribute :timestamp, default: -> { Time.current }
    end
  end
end
```

Now we have a class to create new events. Each time you create a new event, it will be sent to each topic you added via the `event_name` method.

```ruby
AetherObservatory::Examples::ExampleEvent.create(message: 'hello world')
```

Running the command above will display a log message like you see below.

```irb
irb(main):018:0> AetherObservatory::Examples::ExampleEvent.create(message: 'hello world')
[AetherObservatory::Examples::ExampleEvent] Create event for topic: [talkbox.example1]
=> nil
irb(main):019:0> 
```

Now that we have an `ExampleEvent` class to create events we need to create an observer to listen for those events.

<div align="right">
  <a href="#aetherobservatory-guide">Top</a>
</div>

## Creating an Observer and Subscribing to Events

Our new event class `ExampleEvent` creates a new event on the `talkbox.example1` topic so this is the topic we need to create a observer for.

We start by creating another class called `ExampleObserver` that extends the `AetherObservatory::ObserverBase` class. Next we use the `subscribe_to` method to register this observer to the topic `talkbox.example1`. We also need to define a `process` method that will be called each time your observer receives an event. In this `process` method you have access to `event_payload` and `event_name` objects for your own logic.

```ruby
module AetherObservatory
  module Examples
    class ExampleObserver < AetherObservatory::ObserverBase
      subscribe_to 'talkbox.example1'

      def process
        puts <<-EVENT
          ************************************
          Event processed:
          Name: #{event_name.inspect}
          Message: #{event_payload.message}
          Timestamp: #{event_payload.timestamp}
          Event Payload: #{event_payload.inspect}
          ************************************
        EVENT
      end
    end
  end
end
```
Now that we have a new observer named `ExampleObserver`, we will need to start our observer before it will process any events. Observers default to `stopped`, so we need to call `start` on each observer before they will recieve events. Inside an initilizer is the recommended location to start your observers.

```ruby
AetherObservatory::Examples::ExampleObserver.start
```

<div align="right">
  <a href="#aetherobservatory-guide">Top</a>
</div>

## Sending an Event to your Observer

Now that you have all your classes created you can send events to your observer via the `create` method.

```ruby
AetherObservatory::Examples::ExampleEvent.create(message: 'hello world')
```

Calling create on your `ExampleEvent` class will trigger the `process` method in the `ExampleObserver` class. You should see the following logged output.

```irb
irb(main):040:0> AetherObservatory::Examples::ExampleEvent.create(message: 'hello world')
  ************************************
  Event processed:
  Name: "talkbox.example1"
  Message: hello world
  Timestamp: 2024-05-23 15:17:16 UTC
  Event Payload: #<AetherObservatory::Examples::ExampleEvent:0x0000aaaadc2b2118 @attributes=#<ActiveModel::AttributeSet:0x0000aaaadc2b1f38 @attributes={"message"=>#<ActiveModel::Attribute::FromUser:0x0000aaaadc2b1fb0 @name="message", @value_before_type_cast="hello world", @type=#<ActiveModel::Type::Value:0x0000aaaadc101d28 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=#<ActiveModel::Attribute::WithCastValue:0x0000aaaadc2b2dc0 @name="message", @value_before_type_cast=nil, @type=#<ActiveModel::Type::Value:0x0000aaaadc101d28 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=nil>, @value="hello world">, "timestamp"=>#<ActiveModel::Attribute::UserProvidedDefault:0x0000aaaadc2b1f60 @user_provided_value=#<Proc:0x0000aaaadc0f3b38 (irb):15 (lambda)>, @name="timestamp", @value_before_type_cast=#<Proc:0x0000aaaadc0f3b38 (irb):15 (lambda)>, @type=#<ActiveModel::Type::Value:0x0000aaaadc0f3ac0 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=nil, @memoized_value_before_type_cast=Thu, 23 May 2024 15:17:16.082153128 UTC +00:00, @value=Thu, 23 May 2024 15:17:16.082153128 UTC +00:00>}>>
  ************************************
[AetherObservatory::Examples::ExampleEvent] Create event for topic: [talkbox.example1]
=> nil
```

<div align="right">
  <a href="#aetherobservatory-guide">Top</a>
</div>

## Stopping Observers

To stop your observer from processing events you can call the `stop` method on your observer class. This stops only that observer class from processing events.

```ruby
AetherObservatory::Examples::ExampleObserver.stop
```

<div align="right">
  <a href="#aetherobservatory-guide">Top</a>
</div>

## Using Dynamic Event Names

Create a new class called `RandomEvent` that extends `ApplicationEvent`. Then pass a block to the `event_name` method. This allows you to dynamiclly select your topic at the time of event creation.

<sup>*Note: [ApplicationEvent](#creating-events) class was created at the beginning of this guide.*</sup>

```ruby
module AetherObservatory
  module Examples
    class RandomEvent < AetherObservatory::Examples::ApplicationEvent
      event_name { select_a_topic_at_random }

      attribute :message

    private

      def select_a_topic_at_random
        %w(test support customer).sample
      end
    end
  end
end
```

You can now create a few events with your new class using the `create` method of that class.

```ruby
AetherObservatory::Examples::RandomEvent.create(message: 'hello world')
```

As you can see from the following output a random event name is selected each time you call `create`.

```irb
irb(main):078:0> AetherObservatory::Examples::RandomEvent.create(message: 'hello world')
[AetherObservatory::Examples::RandomEvent] Create event for topic: [talkbox.support]
=> nil
irb(main):079:0> AetherObservatory::Examples::RandomEvent.create(message: 'hello world')
[AetherObservatory::Examples::RandomEvent] Create event for topic: [talkbox.test]
=> nil
irb(main):080:0> AetherObservatory::Examples::RandomEvent.create(message: 'hello world')
[AetherObservatory::Examples::RandomEvent] Create event for topic: [talkbox.support]
=> nil
irb(main):081:0> AetherObservatory::Examples::RandomEvent.create(message: 'hello world')
[AetherObservatory::Examples::RandomEvent] Create event for topic: [talkbox.customer]
=> nil
```

<div align="right">
  <a href="#aetherobservatory-guide">Top</a>
</div>

## Multiple Event Topics

In this example we are going to create an event class that sends events to two different topics based on the `level` attribute from the event class. We are also going to make two observer classes that subscribe to different events based on their role in the system.

<sup>*Note: [ApplicationEvent](#creating-events) class was created at the beginning of this guide.*</sup>

We first create the `TalkboxCallQueueEvent` class. This class will send each event to the `talkbox.call_queues.events.all` topic and to the `level` scoped topic.

```ruby
module AetherObservatory
  module Examples
    class TalkboxCallQueueEvent < AetherObservatory::Examples::ApplicationEvent
      event_name 'call_queues.events.all'
      event_name { "call_queues.events.#{level}" }

      attribute :level, default: 'info'
    end
  end
end
```

The new `TalkboxCallQueueEvent` class will send all events to the `all` topic. However the events will also be sent to their specific event `level` scoped topic. This allows us to have one observer logging call history and a second observer that handles events with the scoped `level` or error for topic `talkbox.call_queues.events.error`.

Next we need to create a new class called `TalkboxCallHistoryObserver`. This observer will subscribe to the `talkbox.call_queues.events.all` topic. This classes function is to record all call queue events. 

```ruby
module AetherObservatory
  module Examples
    class TalkboxCallHistoryObserver < AetherObservatory::ObserverBase
      subscribe_to 'talkbox.call_queues.events.all'

      delegate :level, to: :event_payload

      def process
        puts <<-EVENT
          ************************************
          Event processed:
          Name: #{event_name.inspect}
          Level: #{event_payload.level}
          Event Payload: #{event_payload.inspect}
          ************************************
        EVENT
      end
    end
  end
end
```

Next we need a class called `TalkboxCallErrorObserver`. This class only subscribes to the `talkbox.call_queues.events.error` topic. It only cares about `error` level events and nothing else. 

```ruby
module AetherObservatory
  module Examples
    class TalkboxCallErrorObserver < AetherObservatory::ObserverBase
      subscribe_to 'talkbox.call_queues.events.error'

      def process
        puts <<-EVENT
          ************************************
          Error Event processed:
          Name: #{event_name.inspect}
          Level: #{event_payload.level}
          Event Payload: #{event_payload.inspect}
          ************************************
        EVENT
      end
    end
  end
end
```

We need to be sure to start our new observers before they will recieve any events.

```ruby
AetherObservatory::Examples::TalkboxCallHistoryObserver.start
AetherObservatory::Examples::TalkboxCallErrorObserver.start
```

Finally we are ready to create a new event and see what happens. First we create an event with a default level.

```ruby
AetherObservatory::Examples::TalkboxCallQueueEvent.create
```

Running the create with no parameters will have a default level of `info`. You will see the following output.

```irb
irb(main):058:0> AetherObservatory::Examples::TalkboxCallQueueEvent.create
  ************************************
  Event processed:
  Name: "talkbox.call_queues.events.all"
  Level: info
  Event Payload: #<AetherObservatory::Examples::TalkboxCallQueueEvent:0x0000aaab112f75d0 @attributes=#<ActiveModel::AttributeSet:0x0000aaab112f5e88 @attributes={"level"=>#<ActiveModel::Attribute::UserProvidedDefault:0x0000aaab112f73a0 @user_provided_value="info", @name="level", @value_before_type_cast="info", @type=#<ActiveModel::Type::Value:0x0000aaab13a76e08 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=nil, @value="info">}>>
  ************************************
[AetherObservatory::Examples::TalkboxCallQueueEvent] Create event for topic: [talkbox.call_queues.events.all]
[AetherObservatory::Examples::TalkboxCallQueueEvent] Create event for topic: [talkbox.call_queues.events.info]
=> nil
```

Next we will try creating a new event but this time we set the `level` to `error`.

```ruby
AetherObservatory::Examples::TalkboxCallQueueEvent.create(level: 'error')
```

As you can see from the output, setting the `level` to `error` will send an event to both classes. 

```irb
irb(main):059:0> AetherObservatory::Examples::TalkboxCallQueueEvent.create(level: 'error')
  ************************************
  Event processed:
  Name: "talkbox.call_queues.events.all"
  Level: error
  Event Payload: #<AetherObservatory::Examples::TalkboxCallQueueEvent:0x0000aaab135cff30 @attributes=#<ActiveModel::AttributeSet:0x0000aaab135cfe18 @attributes={"level"=>#<ActiveModel::Attribute::FromUser:0x0000aaab135cfe68 @name="level", @value_before_type_cast="error", @type=#<ActiveModel::Type::Value:0x0000aaab13a76e08 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=#<ActiveModel::Attribute::UserProvidedDefault:0x0000aaab135e0bc8 @user_provided_value="info", @name="level", @value_before_type_cast="info", @type=#<ActiveModel::Type::Value:0x0000aaab13a76e08 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=nil>, @value="error">}>>
  ************************************
[AetherObservatory::Examples::TalkboxCallQueueEvent] Create event for topic: [talkbox.call_queues.events.all]
  ************************************
  Error Event processed:
  Name: "talkbox.call_queues.events.error"
  Level: error
  Event Payload: #<AetherObservatory::Examples::TalkboxCallQueueEvent:0x0000aaab135cef90 @attributes=#<ActiveModel::AttributeSet:0x0000aaab135ceea0 @attributes={"level"=>#<ActiveModel::Attribute::FromUser:0x0000aaab135cef40 @name="level", @value_before_type_cast="error", @type=#<ActiveModel::Type::Value:0x0000aaab13a76e08 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=#<ActiveModel::Attribute::UserProvidedDefault:0x0000aaab135e0bc8 @user_provided_value="info", @name="level", @value_before_type_cast="info", @type=#<ActiveModel::Type::Value:0x0000aaab13a76e08 @precision=nil, @scale=nil, @limit=nil>, @original_attribute=nil>, @value="error">}>>
  ************************************
[AetherObservatory::Examples::TalkboxCallQueueEvent] Create event for topic: [talkbox.call_queues.events.error]
=> nil
```

<div align="right">
  <a href="#aetherobservatory-guide">Top</a>
</div>
