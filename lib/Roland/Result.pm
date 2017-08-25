package Roland::Result;

# ABSTRACT: what you get out of a table

use Moose::Role;
use namespace::autoclean;

requires 'as_block_text';
requires 'as_inline_text';
requires 'inline_text_is_lossy';

1;
