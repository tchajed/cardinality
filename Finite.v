Require Iso.
Require Fin.

Set Asymmetric Patterns.

(** A type family which is isomorphic to Fin.t, but defined in
    terms of simpler types by recursion, and is a little bit
    easier to work with. *)
Fixpoint Fin (n : nat) : Set := match n with
  | 0 => Empty_set
  | S n' => (unit + Fin n')%type
  end.

(** Fin and Fin.t are isomorphic for every size. *)
Theorem finIso (n : nat) : Iso.T (Fin.t n) (Fin n).
Proof.
induction n.
- eapply Iso.Build_T.
  intros a. inversion a.
  intros b. inversion b. 
- 
refine (
{| Iso.to := fun x => (match x in Fin.t n'
  return (S n = n') -> Fin (S n) with
   | Fin.F1 _ => fun _ => inl tt
   | Fin.FS n' x' => fun pf => inr (Iso.to IHn (eq_rect n' Fin.t x' _ (eq_sym (eq_add_S _ _ pf))))
   end) eq_refl
 ; Iso.from := fun x => match x with
   | inl tt => Fin.F1
   | inr x' => Fin.FS (Iso.from IHn x')
   end
|}).
intros a.
Require Import Program.
dependent destruction a; simpl.
reflexivity. rewrite Iso.from_to. reflexivity.
intros b. destruct b. destruct u. reflexivity.
  simpl. rewrite Iso.to_from. reflexivity.
Grab Existential Variables.
intros bot. contradiction.
intros f0. inversion f0.
Defined.

Lemma botNull (A : Type) : Iso.T A (A + Empty_set).
Proof.
refine (
{| Iso.to   := inl
 ; Iso.from := fun x => match x with
    | inl x' => x'
    | inr bot => Empty_set_rect (fun _ => A) bot
   end
|}).
reflexivity.
intros b. destruct b. reflexivity. contradiction.
Qed.

Fixpoint split (m : nat)
  : forall (n : nat), Fin.t (m + n) -> (Fin.t m + Fin.t n).
refine (
  match m return (forall (n : nat), Fin.t (m + n) -> (Fin.t m + Fin.t n)) with
  | 0 => fun _ => inr
  | S m' => fun n x => (match x as x0 in Fin.t k 
    return forall (pf : k = (S m' + n)), (Fin.t (S m') + Fin.t n) with
    | Fin.F1 _ => fun pf => inl Fin.F1
    | Fin.FS n' x' => fun pf => _
    end) eq_refl
  end).
simpl in pf.
apply eq_add_S in pf.
rewrite pf in x'.
refine (match split m' n x' with
  | inl a => inl (Fin.FS a)
  | inr b => inr b
  end).
Defined.

Lemma splitL : forall {m n : nat} {x : Fin.t m},
  split m n (Fin.L n x) = inl x.
Proof.
intros m. induction m; intros n x.
- inversion x.
- dependent destruction x; simpl.
  + reflexivity.
  + rewrite (IHm n x). reflexivity.
Qed.

Lemma splitR : forall {m n : nat} {x : Fin.t n},
  split m n (Fin.R m x) = inr x.
Proof.
intros m. induction m; intros n x; simpl.
- reflexivity.
- rewrite (IHm n x). reflexivity.
Qed.

Lemma splitInj : forall {m n : nat} {x y : Fin.t (m + n)},
  split m n x = split m n y -> x = y.
Proof.
intros m; induction m; intros n x y Heq.
- inversion Heq. reflexivity.
- dependent destruction x; dependent destruction y.
  + reflexivity.
  + simpl in Heq. destruct (split m n y); inversion Heq.
  + simpl in Heq. destruct (split m n x); inversion Heq.
  + apply f_equal. simpl in Heq. apply IHm.
    destruct (split m n x) eqn:sx;
    destruct (split m n y) eqn:sy.
    apply f_equal. 
    assert (forall (A B : Type) (x y : A), @inl A B x = @inl A B y -> x = y).
    intros A B x0 y0 Heqn. inversion Heqn. reflexivity.
    apply H in Heq. apply Fin.FS_inj in Heq. assumption.
    inversion Heq. inversion Heq. apply f_equal. injection Heq. trivial.
Qed.

Fixpoint splitMult (m : nat)
  : forall (n : nat), Fin.t (m * n) -> (Fin.t m * Fin.t n) 
  := match m return (forall (n : nat), Fin.t (m * n) -> (Fin.t m * Fin.t n)) with
  | 0 => fun _ => Fin.case0 _
  | S m' => fun n x => match split n (m' * n) x with
    | inl a => (Fin.F1, a)
    | inr b => match splitMult m' n b with
      | (x, y) => (Fin.FS x, y)
      end
    end
  end.


Lemma finPlus : forall {m n : nat},
  Iso.T (Fin.t m + Fin.t n) (Fin.t (m + n)).
Proof.
intros m n.
refine (
{| Iso.to := fun x => match x with
   | inl a => Fin.L n a
   | inr b => Fin.R m b
   end
 ; Iso.from := split m n
|}).
intros. destruct a; simpl. induction m; simpl.
- inversion t.
Require Import Program.
- dependent destruction t; simpl.
  + reflexivity.
  + rewrite IHm. reflexivity.
- induction m; simpl. reflexivity. rewrite IHm. reflexivity.
- induction m; intros; simpl.
  + reflexivity.
  + dependent destruction b; simpl. reflexivity.
     pose proof (IHm b).
     destruct (split m n b) eqn:seqn;
     simpl; rewrite H; reflexivity.
Qed.

Lemma finMult : forall {m n : nat},
  Iso.T (Fin.t m * Fin.t n) (Fin.t (m * n)).
Proof.
intros m n.
refine (
{| Iso.to := fun x => match x with (a, b) => Fin.depair a b end
 ; Iso.from := splitMult m n
|}).
intros p. destruct p.
induction m; simpl.
- inversion t.
- dependent destruction t; simpl.
  + rewrite splitL. reflexivity.
  + rewrite splitR. rewrite (IHm t). reflexivity.

- induction m; intros b; simpl.
  + inversion b.
  + destruct (split n (m * n) b) eqn:seqn.
    * simpl. rewrite <- splitL in seqn. 
      apply splitInj in seqn. symmetry. assumption.
    * pose proof (IHm t). assert (b = Fin.R n t).
      apply (@splitInj n (m * n)). 
      rewrite seqn. symmetry. apply splitR.
      rewrite H0. simpl.
      destruct (splitMult m n t) eqn:smeqn.
      simpl. rewrite <- H. reflexivity.
Defined.

Fixpoint pow (b e : nat) : nat := match e with
  | 0 => 1
  | S e' => b * pow b e'
  end.

Theorem finPow : forall {e b : nat},
  Iso.T (Fin.t (pow b e)) (Fin.t e -> Fin.t b).
Proof.
intros e. induction e; intros n; simpl.
- eapply Iso.Trans. apply finIso. simpl. eapply Iso.Trans.
  eapply Iso.Sym. apply botNull. eapply Iso.Trans. Focus 2.
  eapply Iso.FuncCong. eapply Iso.Sym. apply finIso. apply Iso.Refl.
  simpl. apply Iso.Sym. apply Iso.FFunc.
- eapply Iso.Trans. eapply Iso.Sym. apply finMult.
  eapply Iso.Trans. Focus 2. eapply Iso.FuncCong.
  eapply Iso.Sym. apply finIso. apply Iso.Refl.
  simpl. eapply Iso.Trans. Focus 2. eapply Iso.Sym. eapply Iso.PlusFunc.
  apply Iso.TFunc. eapply Iso.Trans. eapply Iso.FuncCong.
  eapply Iso.Sym. apply finIso. apply Iso.Refl. eapply Iso.Sym.
  apply IHe. apply Iso.Refl.
Qed.

(** A universe of codes for finite types. *)
Inductive U : Set :=
  | U0    : U
  | U1    : U
  | UPlus : U -> U -> U
  | UTimes : U -> U -> U
  | UFunc : U -> U -> U
  | UFint : nat -> U
  | UFin : nat -> U.

(** The types which the codes of U represent. *)
Fixpoint ty (t : U) : Set := match t with
  | U0 => Empty_set
  | U1 => unit
  | UPlus a b => (ty a + ty b)%type
  | UTimes a b => (ty a * ty b)%type
  | UFunc a b => ty a -> ty b
  | UFint n => Fin.t n
  | UFin n => Fin n
  end.

(** For every code for a finite type, we give its cardinality as
    a natural number. *)
Fixpoint card (t : U) : nat := match t with
  | U0 => 0
  | U1 => 1
  | UPlus a b => card a + card b
  | UTimes a b => card a * card b
  | UFunc a b => pow (card b) (card a)
  | UFint n => n
  | UFin n => n
  end.
    
(** Each type in the finite universe is isomorphic to the Fin.t
    family whose size is determined by the cardinality function above. *)
Theorem finChar (t : U) : Iso.T (ty t) (Fin.t (card t)).
Proof.
induction t; simpl.
- apply Iso.Sym. apply (finIso 0).
- apply Iso.Sym. apply (@Iso.Trans _ (Fin 1)). apply (finIso 1).
  apply Iso.Sym. apply botNull.
- eapply Iso.Trans. eapply Iso.PlusCong. eassumption.
  eassumption.
  apply finPlus.
- eapply Iso.Trans. eapply Iso.TimesCong; try eassumption.
  apply finMult.
- eapply Iso.Trans. eapply Iso.FuncCong; try eassumption.
  apply Iso.Sym. apply finPow.
- apply Iso.Refl.
- apply Iso.Sym. apply finIso.
Qed.

(** A type for evidence that a type is finite: a type is finite if
    any of the following hold:
    a) it is unit
    b) it is Empty_set
    c) it is a sum of finite types
    d) it is isomorphic to a finite type

    This is not minimal. We could have replaced b) and c) with the condition
    e) it is the sum of unit with a finite type
       (this is the analog of Successor)
    But this definition is simple so I like it.
*)

Inductive T : Type -> Type :=
  | F0 : T Empty_set
  | FS : forall {A}, T A -> T (unit + A)
  | FIso : forall {A B}, T A -> Iso.T A B -> T B
.

Definition fin (n : nat) : T (Fin.t n).
Proof. eapply FIso. Focus 2. eapply Iso.Sym. eapply finIso.
induction n; simpl.
- apply F0.
- apply FS. assumption.
Qed.

Definition finU (A : U) : T (ty A).
Proof. 
eapply FIso. Focus 2. eapply Iso.Sym. apply finChar.
apply fin.
Qed.

Definition iso {A : Type} : T A -> sigT (fun n => Iso.T A (Fin.t n)).
Proof.
intros. induction X.
-  exists 0. apply (finChar U0).
- destruct IHX. exists (S x). apply Iso.Sym. eapply Iso.Trans. 
  apply finIso. simpl. apply Iso.PlusCong. apply Iso.Refl.
  eapply Iso.Trans. eapply Iso.Sym. apply finIso. apply Iso.Sym.
  assumption.
- destruct IHX. exists x. eapply Iso.Trans. eapply Iso.Sym. eassumption.
  assumption. 
Qed.

Definition true : T unit := finU U1.

Definition plus {A B : Type} (fa : T A) (fb : T B) : T (A + B).
Proof.
destruct (iso fa), (iso fb).
eapply (@FIso (Fin.t (x + x0))). apply (finU (UFint (x + x0))).
eapply Iso.Trans. eapply Iso.Sym. apply finPlus.
eapply Iso.PlusCong; eapply Iso.Sym; eassumption.
Qed.

Lemma finiteSig {A : Type} (fa : T A)
  : forall {B : A -> Type}, 
  (forall (x : A), T (B x))
  -> sigT (fun S => (T S * Iso.T (sigT B) S)%type).
Proof.
induction fa; intros b fb.
- exists Empty_set. split. constructor. apply Iso.FSig.
- pose proof (IHfa (fun x => b (inr x)) (fun x => fb (inr x))).
  destruct X. destruct p.
  exists (b (inl tt) + x)%type. constructor. apply plus. apply fb.
  assumption.
  apply Iso.PlusSig. apply (@Iso.TSig (fun x => b (inl x))). 
  assumption.
- pose (Iso.Sym t).
  pose proof (IHfa (fun x => b (Iso.from t0 x))
                   (fun x => fb (Iso.from t0 x))).
  destruct X. destruct p.
  exists x. split. assumption.
  eapply Iso.Trans. Focus 2. apply t2.
  admit.
  (* Here we need Iso.sigmaProp, which we have yet to prove,
     so we cannot finish the proof here. *)
  (*apply Iso.sigmaProp.*)
Admitted.

(** Sigma types are closed under finiteness. *)
Theorem sig {A : Type} {B : A -> Type} 
  : T A 
  -> (forall (x : A), T (B x))
  -> T (sigT B).
Proof.
intros fA fB.
pose proof (finiteSig fA fB).
destruct X. destruct p.
eapply FIso. apply t.
apply Iso.Sym. assumption.
Defined.

(** Product types are closed under finiteness. *)
Theorem times {A B : Type} : T A -> T B -> T (A * B).
Proof.
intros fa fb.
eapply FIso. Focus 2. eapply Iso.Sym. eapply Iso.sigTimes.
apply sig. assumption. apply (fun _ => fb).
Defined.

Lemma finiteMapped {A : Type} (fa : T A)
  : forall {B : Type}, T B -> sigT (fun S => (T S * Iso.T (A -> B) S)%type).
Proof.
induction fa.
- intros. exists unit. apply (true, Iso.FFunc).
- intros B fb.
  destruct (IHfa B fb).
  exists (B * x)%type.
  destruct p.
  apply (times fb t , Iso.PlusFunc Iso.TFunc t0).
- intros B1 fb.
  destruct (IHfa B1 fb).
  destruct p.
  exists x.
  split.
  assumption.  
  eapply Iso.Trans.
  eapply Iso.Sym.
  apply (Iso.FuncCong t (Iso.Refl B1)).
  assumption.
Defined.

(** Functions are closed under finiteness. *)
Theorem func {A B : Type} : T A -> T B -> T (A -> B).
Proof.
intros FA FB.
pose proof (finiteMapped FA FB).
destruct X.
destruct p.
eapply FIso.
eassumption.
apply Iso.Sym.
assumption.
Defined.

(** Any finite type has decidable equality. *)
Theorem eq_dec {A : Type} : T A -> forall a b : A, {a = b} + {a <> b}.
Proof.
intros finite.
induction finite; intros; try (decide equality).
- destruct a0, u; auto.
- eapply Iso.eq_dec; eassumption.
Qed.