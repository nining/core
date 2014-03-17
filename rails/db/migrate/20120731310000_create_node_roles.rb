# Copyright 2014, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class CreateNodeRoles < ActiveRecord::Migration
  def change
    create_table :node_roles do |t|
      t.belongs_to  :snapshot,          null: false
      t.foreign_key :snapshots
      t.belongs_to  :role,              null: false
      t.foreign_key :roles
      t.belongs_to  :node,              null: false
      t.foreign_key :nodes
      t.integer     :state,             null: false, default: NodeRole::PROPOSED
      t.integer     :cohort,            null: false, default: 0
      t.integer     :run_count,         null: false, default: 0
      t.string      :status,            null: true   # expected for error, blocked, transistioning
      t.text        :runlog,            null: false, default: ""
      t.boolean     :available,         null: false, default: true
      t.integer     :order,             default: 10000
      t.json        :proposed_data,     null: false, default: {}
      t.json        :committed_data,    null: true
      t.json        :sysdata,           null: false, default: {}
      t.json        :wall,              null: false, default: {}
      t.timestamps
    end
    #natural key
    add_index(:node_roles, [:role_id, :node_id], unique: true)
    add_index(:node_roles, :snapshot_id)

    create_table :node_role_pcms, id: false do |t|
      t.integer     :parent_id
      t.foreign_key :node_roles, name: 'parent_fk', column: 'parent_id'
      t.integer     :child_id
      t.foreign_key :node_roles, name: 'child_fk', column: 'child_id'
    end
    add_index(:node_role_pcms, [:parent_id, :child_id], unique: true)
    add_index(:node_role_pcms, :child_id)

    # Create a view that expands all node_role_pcms to include all the
    # recursive parents and children of a node.
    # This is very postgresql 9.3 specific.
   execute "
create or replace recursive view node_role_all_pcms (child_id, parent_id) as
      select child_id, parent_id from node_role_pcms
      union
      select p.child_id, pcm.parent_id from node_role_pcms pcm, node_role_all_pcms p
      where pcm.child_id = p.parent_id;"
  end
end
