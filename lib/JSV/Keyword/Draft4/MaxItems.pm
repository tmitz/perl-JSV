package JSV::Keyword::Draft4::MaxItems;

use strict;
use warnings;
use parent qw(JSV::Keyword);

use JSV::Keyword qw(:constants);

sub instance_type() { INSTANCE_TYPE_ARRAY(); }
sub keyword() { "maxItems" }
sub keyword_priority() { 10; }

sub validate {
    my ($class, $context, $schema, $instance) = @_;

    my $keyword_value = $class->keyword_value($schema);

    if (scalar(@$instance) > $keyword_value) {
        $context->log_error("The instance array length is greater than maxItems value");
    }
}

1;
