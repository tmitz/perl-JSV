package JSV::Context;

use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/
        keywords
        reference
        original_schema
        throw_error
        throw_immediate
        history
        enable_history
        json
    /],
    ro  => [qw/
        errors
        current_type
        current_keyword
        current_pointer
        current_instance
        current_schema
    /],
);

use JSON::XS;
use JSV::Keyword qw(:constants);
use JSV::Util::Type qw(detect_instance_type);
use JSV::Exception;


sub validate {
    my ($self, $schema, $instance) = @_;

    local $self->{current_type} = detect_instance_type($instance);

    my $rv;
    eval {
        for (@{ $self->keywords->{INSTANCE_TYPE_ANY()} }) {
            next unless exists $schema->{$_->keyword};
            $self->apply_keyword($_, $schema, $instance);
        }

        if ($self->current_type eq "integer" || $self->current_type eq "number") {
            for (@{ $self->keywords->{INSTANCE_TYPE_NUMERIC()} }) {
                next unless exists $schema->{$_->keyword};
                $self->apply_keyword($_, $schema, $instance);
            }
        }
        elsif ($self->current_type eq "string") {
            for (@{ $self->keywords->{INSTANCE_TYPE_STRING()} }) {
                next unless exists $schema->{$_->keyword};
                $self->apply_keyword($_, $schema, $instance);
            }
        }
        elsif ($self->current_type eq "array") {
            for (@{ $self->keywords->{INSTANCE_TYPE_ARRAY()} }) {
                next unless exists $schema->{$_->keyword};
                $self->apply_keyword($_, $schema, $instance);
            }
        }
        elsif ($self->current_type eq "object") {
            for (@{ $self->keywords->{INSTANCE_TYPE_OBJECT()} }) {
                next unless exists $schema->{$_->keyword};
                $self->apply_keyword($_, $schema, $instance);
            }
        }

        $rv = 1;
    };
    if ( scalar @{ $self->errors } ) {
        if ( $self->throw_error ) {
            JSV::Exception->throw(
                errors => $self->errors,
                ($self->enable_history ? (history => $self->history) : ()),
            );
        }
        $rv = 0;
    }

    return $rv;
}

sub apply_keyword {
    my ($self, $keyword, $schema, $instance) = @_;

    local $self->{current_errors}   = [];
    local $self->{current_keyword}  = $_->keyword;
    local $self->{current_schema}   = $schema;
    local $self->{current_instance} = $instance;

    if ( $self->enable_history ) {
        push @{ $self->history }, +{
            keyword  => $self->current_keyword,
            pointer  => $self->current_pointer,
            schema   => $self->current_schema,
            instance => $instance,
        };
    }

    $_->validate($self, $schema, $instance);
}

sub log_error {
    my ($self, $message) = @_;

    my $instance;
    if ( ref $self->current_instance ) {
        if ( $self->current_instance == JSON::XS::true ) {
            $instance = "true";
        }
        elsif ( $self->current_instance == JSON::XS::false ) {
            $instance = "false";
        }
    }
    else {
        $instance = $self->current_instance;
    }

    my $error = +{
        keyword  => $self->current_keyword,
        pointer  => $self->current_pointer,
        schema   => $self->current_schema,
        instance => $instance,
        message  => $message,
    };

    if ( $ENV{JSV_DEBUG} ) {
        use Data::Dump qw/dump/;
        warn dump($self->history);
        warn dump($error);
    }

    if ( $self->throw_immediate ) {
        JSV::Exception->throw(
            error => $error,
            ($self->enable_history ? (history => $self->history) : ()),
        );
    }
    else {
        push @{ $self->{errors} }, $error;
    }
}

1;
