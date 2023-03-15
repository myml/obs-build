################################################################
#
# Copyright (c) 2011-2023 Wuhan Deepin Technology Co., Ltd. 
# Author: myml <wurongjie@deepin.org>
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 or 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################

package Build::Linglong;

use strict;

eval { require YAML::XS; $YAML::XS::LoadBlessed = 0; };
*YAML::XS::LoadFile = sub {die("YAML::XS is not available\n")} unless defined &YAML::XS::LoadFile;

sub toDepth {
  my($package) = @_;
  my $id = $package->{'id'};
  my $version = $package->{'version'};
  # 判断是否将包名和版本号写一起的简写模式，如 org.deepin.base/20.5.12
  my @spl = split('/', $package->{'id'});
  if(scalar(@spl)>1) {
    $id = $spl[0];
    $version = $spl[1];
  }
  # debian 包名不支持大写，转为小写字符
  $id = lc($id);
  # 如果版本号小余四位，转为范围限制 
  # 如 org.deepin.base/20.5.12 会转为 linglong.org.deepin.base (>= 20.5.12), linglong.org.deepin.base (< 20.5.13)
  my @vs = split('\.', $version);
  if(scalar(@vs) < 4) {
    my $min = $version;
    $vs[-1] = $vs[-1]+1;
    my $max = join('.', @vs);
    return 'linglong.'.$id.' (>= '.$min.'), '.'linglong.'.$id.' (<< '.$max.')'
  }
  # 版本号是四位，则使用固定限制
  return 'linglong.'.$id.' (= '.$version.')'
}

sub parse {
  my ($cf, $fn) = @_;
  
  my $yml;
  eval { $yml = YAML::XS::LoadFile($fn); };
  return {'error' => "Failed to parse yml file"} unless $yml;
  my $ret = {};
  $ret->{'name'} = $yml->{'package'}->{'id'};
  $ret->{'version'} = $yml->{'package'}->{'version'} || "0";

  my @packdeps;
  if($yml->{'runtime'}) {
    push @packdeps, toDepth($yml->{'runtime'}); 
  }

  if($yml->{'base'}) {
    push @packdeps, toDepth($yml->{'base'});
  }
  
  if($yml->{'depends'}) {
    for my $depend (@{$yml->{'depends'}}) {
      push @packdeps, toDepth($depend);
    }
  }

  $ret->{'deps'} = \@packdeps;

  my @sources;
  $ret->{'sources'} = \@sources;
   
  return $ret;
}

1;
